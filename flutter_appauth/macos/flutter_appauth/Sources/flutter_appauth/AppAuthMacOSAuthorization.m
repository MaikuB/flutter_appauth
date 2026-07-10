#import "AppAuthMacOSAuthorization.h"

#import <AuthenticationServices/AuthenticationServices.h>

@interface AppAuthMacOSAuthorization () <ASWebAuthenticationPresentationContextProviding>
@property(nonatomic, strong) ASWebAuthenticationSession *manualAuthSession;
@end

@implementation AppAuthMacOSAuthorization

- (BOOL)shouldUsePkceForResponseTypes:(NSArray *)responseTypes {
  if (responseTypes == nil || responseTypes.count == 0) {
    return YES;
  }
  return [responseTypes containsObject:@"code"];
}

- (NSString *)responseTypeStringForResponseTypes:(NSArray *)responseTypes {
  if (responseTypes != nil && responseTypes.count > 0) {
    return [responseTypes componentsJoinedByString:@" "];
  }
  return OIDResponseTypeCode;
}

- (BOOL)isAppAuthSupportedResponseType:(NSString *)responseType {
  NSString *codeIdToken = [@[OIDResponseTypeCode, OIDResponseTypeIDToken]
      componentsJoinedByString:@" "];
  NSString *idTokenCode = [@[OIDResponseTypeIDToken, OIDResponseTypeCode]
      componentsJoinedByString:@" "];

  return [responseType isEqualToString:OIDResponseTypeCode]
         || [responseType isEqualToString:codeIdToken]
         || [responseType isEqualToString:idTokenCode];
}

- (NSDictionary<NSString *, NSString *> *)
    parseParametersFromString:(NSString *)parameterString {
  NSMutableDictionary<NSString *, NSString *> *parameters =
      [[NSMutableDictionary alloc] init];
  for (NSString *pair in [parameterString componentsSeparatedByString:@"&"]) {
    NSRange range = [pair rangeOfString:@"="];
    if (range.location == NSNotFound) {
      continue;
    }
    NSString *key =
        [[pair substringToIndex:range.location] stringByRemovingPercentEncoding];
    NSString *value =
        [[pair substringFromIndex:range.location + 1]
            stringByRemovingPercentEncoding];
    if (key.length > 0) {
      parameters[key] = value ?: @"";
    }
  }
  return parameters;
}

- (NSDictionary<NSString *, NSString *> *)parametersFromCallbackURL:
    (NSURL *)callbackURL {
  if (callbackURL.fragment.length > 0) {
    return [self parseParametersFromString:callbackURL.fragment];
  }
  if (callbackURL.query.length > 0) {
    return [self parseParametersFromString:callbackURL.query];
  }
  return @{};
}

- (NSURL *)authorizationURLWithConfiguration:
                (OIDServiceConfiguration *)serviceConfiguration
                                    clientId:(NSString *)clientId
                                      scopes:(NSArray *)scopes
                                 redirectUrl:(NSString *)redirectUrl
                                responseType:(NSString *)responseType
                                       state:(NSString *)state
                                       nonce:(NSString *)nonce
                        additionalParameters:
                            (NSDictionary *)additionalParameters {
  NSMutableDictionary<NSString *, NSString *> *parameters =
      [[NSMutableDictionary alloc] init];
  parameters[@"client_id"] = clientId;
  parameters[@"redirect_uri"] = redirectUrl;
  parameters[@"response_type"] = responseType;
  parameters[@"state"] = state;
  parameters[@"nonce"] = nonce;

  NSString *scope = [OIDScopeUtilities scopesWithArray:scopes];
  if (scope.length > 0) {
    parameters[@"scope"] = scope;
  }

  if (additionalParameters != nil) {
    [parameters addEntriesFromDictionary:additionalParameters];
  }

  NSURLComponents *components = [NSURLComponents
      componentsWithURL:serviceConfiguration.authorizationEndpoint
                            resolvingAgainstBaseURL:NO];
  NSMutableArray<NSURLQueryItem *> *queryItems =
      [[NSMutableArray alloc] init];
  [parameters
      enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSString *value,
                                           BOOL *stop) {
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key
                                                          value:value]];
      }];
  components.queryItems = queryItems;
  return components.URL;
}

- (id<OIDExternalUserAgentSession>)
    performManualImplicitAuthorization:
        (OIDServiceConfiguration *)serviceConfiguration
                              clientId:(NSString *)clientId
                                scopes:(NSArray *)scopes
                           redirectUrl:(NSString *)redirectUrl
                          responseType:(NSString *)responseType
                                 state:(NSString *)state
                                 nonce:(NSString *)nonce
                  additionalParameters:(NSDictionary *)additionalParameters
                     externalUserAgent:(NSNumber *)externalUserAgent
                                result:(FlutterResult)result {
  NSURL *authorizationURL =
      [self authorizationURLWithConfiguration:serviceConfiguration
                                     clientId:clientId
                                       scopes:scopes
                                  redirectUrl:redirectUrl
                                 responseType:responseType
                                        state:state
                                        nonce:nonce
                         additionalParameters:additionalParameters];
  NSURL *redirectNSURL = [NSURL URLWithString:redirectUrl];
  NSString *callbackScheme = redirectNSURL.scheme;
  if (authorizationURL == nil || callbackScheme.length == 0) {
    [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                            message:@"Invalid authorization URL or redirect scheme"
                             result:result
                              error:nil];
    return nil;
  }

  if (@available(macOS 10.15, *)) {
    __weak AppAuthMacOSAuthorization *weakSelf = self;
    ASWebAuthenticationSession *session =
        [[ASWebAuthenticationSession alloc]
                  initWithURL:authorizationURL
            callbackURLScheme:callbackScheme
            completionHandler:^(NSURL *_Nullable callbackURL,
                                NSError *_Nullable error) {
              __strong AppAuthMacOSAuthorization *strongSelf = weakSelf;
              if (!strongSelf) {
                return;
              }
              strongSelf.manualAuthSession = nil;

              if (callbackURL == nil) {
                [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                                        message:[FlutterAppAuth
                                                    formatMessageWithError:
                                                        AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                                         error:error]
                                         result:result
                                          error:error];
                return;
              }

              NSDictionary<NSString *, NSString *> *tokenParameters =
                  [strongSelf parametersFromCallbackURL:callbackURL];
              if (tokenParameters[@"error"] != nil) {
                NSString *message = tokenParameters[@"error_description"]
                                        ?: tokenParameters[@"error"];
                [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                                        message:message
                                         result:result
                                          error:nil];
                return;
              }

              NSString *responseState = tokenParameters[@"state"];
              if (state.length > 0 &&
                  ![state isEqualToString:responseState ?: @""]) {
                [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                                        message:@"Response state param did not "
                                                @"match request state"
                                         result:result
                                          error:nil];
                return;
              }

              NSMutableDictionary *processedResponse =
                  [[NSMutableDictionary alloc] init];
              [processedResponse setObject:@{} forKey:@"authorizationAdditionalParameters"];
              if (tokenParameters[@"id_token"] != nil) {
                processedResponse[@"idToken"] = tokenParameters[@"id_token"];
              }
              if (tokenParameters[@"access_token"] != nil) {
                processedResponse[@"accessToken"] =
                    tokenParameters[@"access_token"];
              }
              if (tokenParameters[@"code"] != nil) {
                processedResponse[@"authorizationCode"] = tokenParameters[@"code"];
              }
              processedResponse[@"nonce"] = nonce;
              result(processedResponse);
            }];

    session.presentationContextProvider = self;
    if ([externalUserAgent integerValue] ==
        EphemeralASWebAuthenticationSession) {
      session.prefersEphemeralWebBrowserSession = YES;
    }

    self.manualAuthSession = session;
    if (![session start]) {
      self.manualAuthSession = nil;
      [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                              message:@"Unable to start web authentication session"
                               result:result
                                error:nil];
    }
  } else {
    [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                            message:@"Implicit OAuth flows require macOS 10.15 or later"
                             result:result
                              error:nil];
  }

  return nil;
}

- (id<OIDExternalUserAgentSession>)
    performAuthorization:(OIDServiceConfiguration *)serviceConfiguration
                clientId:(NSString *)clientId
            clientSecret:(NSString *)clientSecret
                  scopes:(NSArray *)scopes
             redirectUrl:(NSString *)redirectUrl
    additionalParameters:(NSDictionary *)additionalParameters
       externalUserAgent:(NSNumber *)externalUserAgent
                  result:(FlutterResult)result
            exchangeCode:(BOOL)exchangeCode
                   nonce:(NSString *)nonce
            responseTypes:(NSArray *)responseTypes {
  NSString *responseTypeString =
      [self responseTypeStringForResponseTypes:responseTypes];
  NSString *requestNonce = nonce != nil
                               ? nonce
                               : [OIDAuthorizationRequest generateState];
  NSString *state = [OIDAuthorizationRequest generateState];

  if (![self isAppAuthSupportedResponseType:responseTypeString]) {
    return [self performManualImplicitAuthorization:serviceConfiguration
                                           clientId:clientId
                                             scopes:scopes
                                        redirectUrl:redirectUrl
                                       responseType:responseTypeString
                                              state:state
                                              nonce:requestNonce
                               additionalParameters:additionalParameters
                                  externalUserAgent:externalUserAgent
                                             result:result];
  }

  BOOL usePkce = [self shouldUsePkceForResponseTypes:responseTypes];
  NSString *codeVerifier = nil;
  NSString *codeChallenge = nil;
  NSString *codeChallengeMethod = nil;

  if (usePkce) {
    codeVerifier = [OIDAuthorizationRequest generateCodeVerifier];
    codeChallenge =
        [OIDAuthorizationRequest codeChallengeS256ForVerifier:codeVerifier];
    codeChallengeMethod = OIDOAuthorizationRequestCodeChallengeMethodS256;
  }

  OIDAuthorizationRequest *request = [[OIDAuthorizationRequest alloc]
      initWithConfiguration:serviceConfiguration
                   clientId:clientId
               clientSecret:clientSecret
                      scope:[OIDScopeUtilities scopesWithArray:scopes]
                redirectURL:[NSURL URLWithString:redirectUrl]
               responseType:responseTypeString
                      state:state
                      nonce:requestNonce
               codeVerifier:codeVerifier
              codeChallenge:codeChallenge
        codeChallengeMethod:codeChallengeMethod
       additionalParameters:additionalParameters];
  if (request == nil) {
    [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE
                            message:@"Unsupported OAuth response type"
                             result:result
                              error:nil];
    return nil;
  }

  NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
  if (exchangeCode) {
    NSObject<OIDExternalUserAgent> *agent =
        [self userAgentWithPresentingWindow:keyWindow
                          externalUserAgent:externalUserAgent];
    return [OIDAuthState
        authStateByPresentingAuthorizationRequest:request
                                externalUserAgent:agent
                                         callback:^(
                                             OIDAuthState *_Nullable authState,
                                             NSError *_Nullable error) {
                                           if (authState) {
                                             result([FlutterAppAuth
                                                 processResponses:
                                                     authState.lastTokenResponse
                                                     authResponse:
                                                         authState
                                                             .lastAuthorizationResponse]);

                                           } else {
                                             [FlutterAppAuth
                                                 finishWithError:
                                                     AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE
                                                         message:
                                                             [FlutterAppAuth
                                                                 formatMessageWithError:
                                                                     AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                                                  error:
                                                                                      error]
                                                          result:result
                                                           error:error];
                                           }
                                         }];
  } else {
    NSObject<OIDExternalUserAgent> *agent =
        [self userAgentWithPresentingWindow:keyWindow
                          externalUserAgent:externalUserAgent];
    return [OIDAuthorizationService
        presentAuthorizationRequest:request
                  externalUserAgent:agent
                           callback:^(OIDAuthorizationResponse
                                          *_Nullable authorizationResponse,
                                      NSError *_Nullable error) {
                             if (authorizationResponse) {
                               NSMutableDictionary *processedResponse =
                                   [[NSMutableDictionary alloc] init];
                               [processedResponse
                                   setObject:authorizationResponse
                                                 .additionalParameters
                                                 ?: @{}
                                      forKey:
                                          @"authorizationAdditionalParameters"];
                               if (authorizationResponse.authorizationCode) {
                                 [processedResponse
                                     setObject:authorizationResponse
                                                   .authorizationCode
                                        forKey:@"authorizationCode"];
                               }
                               if (authorizationResponse.request.codeVerifier) {
                                 [processedResponse
                                     setObject:authorizationResponse.request
                                                   .codeVerifier
                                        forKey:@"codeVerifier"];
                               }
                               if (authorizationResponse.request.nonce) {
                                 [processedResponse
                                     setObject:authorizationResponse.request.nonce
                                        forKey:@"nonce"];
                               }
                               if (authorizationResponse.idToken) {
                                 [processedResponse
                                     setObject:authorizationResponse.idToken
                                        forKey:@"idToken"];
                               }
                               if (authorizationResponse.accessToken) {
                                 [processedResponse
                                     setObject:authorizationResponse.accessToken
                                        forKey:@"accessToken"];
                               }
                               result(processedResponse);
                             } else {
                               [FlutterAppAuth
                                   finishWithError:AUTHORIZE_ERROR_CODE
                                           message:
                                               [FlutterAppAuth
                                                   formatMessageWithError:
                                                       AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                                    error:error]
                                            result:result
                                             error:error];
                             }
                           }];
  }
}

- (id<OIDExternalUserAgentSession>)
    performEndSessionRequest:(OIDServiceConfiguration *)serviceConfiguration
           requestParameters:(EndSessionRequestParameters *)requestParameters
                      result:(FlutterResult)result {
  NSURL *postLogoutRedirectURL =
      requestParameters.postLogoutRedirectUrl
          ? [NSURL URLWithString:requestParameters.postLogoutRedirectUrl]
          : nil;

  OIDEndSessionRequest *endSessionRequest =
      requestParameters.state
          ? [[OIDEndSessionRequest alloc]
                initWithConfiguration:serviceConfiguration
                          idTokenHint:requestParameters.idTokenHint
                postLogoutRedirectURL:postLogoutRedirectURL
                                state:requestParameters.state
                 additionalParameters:requestParameters.additionalParameters]
          : [[OIDEndSessionRequest alloc]
                initWithConfiguration:serviceConfiguration
                          idTokenHint:requestParameters.idTokenHint
                postLogoutRedirectURL:postLogoutRedirectURL
                 additionalParameters:requestParameters.additionalParameters];

  NSWindow *keyWindow = [[NSApplication sharedApplication] keyWindow];
  id<OIDExternalUserAgent> externalUserAgent =
      [self userAgentWithPresentingWindow:keyWindow
                        externalUserAgent:requestParameters.externalUserAgent];

  return [OIDAuthorizationService
      presentEndSessionRequest:endSessionRequest
             externalUserAgent:externalUserAgent
                      callback:^(
                          OIDEndSessionResponse *_Nullable endSessionResponse,
                          NSError *_Nullable error) {
                        if (!endSessionResponse) {
                          NSString *message = [NSString
                              stringWithFormat:END_SESSION_ERROR_MESSAGE_FORMAT,
                                               [error localizedDescription]];
                          [FlutterAppAuth finishWithError:END_SESSION_ERROR_CODE
                                                  message:message
                                                   result:result
                                                    error:error];
                          return;
                        }
                        NSMutableDictionary *processedResponse =
                            [[NSMutableDictionary alloc] init];
                        [processedResponse setObject:endSessionResponse.state
                                              forKey:@"state"];
                        result(processedResponse);
                      }];
}

- (id<OIDExternalUserAgent>)
    userAgentWithPresentingWindow:(NSWindow *)presentingWindow
                externalUserAgent:(NSNumber *)externalUserAgent {
  if ([externalUserAgent integerValue] == EphemeralASWebAuthenticationSession) {
    return [[OIDExternalUserAgentMacNoSSO alloc]
        initWithPresentingWindow:presentingWindow];
  }
  return [[OIDExternalUserAgentMac alloc]
      initWithPresentingWindow:presentingWindow];
}

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:
    (ASWebAuthenticationSession *)session API_AVAILABLE(macos(10.15)) {
  return [[NSApplication sharedApplication] keyWindow];
}

@end
