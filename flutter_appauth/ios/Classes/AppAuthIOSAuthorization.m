#import "AppAuthIOSAuthorization.h"

@implementation AppAuthIOSAuthorization

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
                   nonce:(NSString *)nonce {
  NSString *codeVerifier = [OIDAuthorizationRequest generateCodeVerifier];
  NSString *codeChallenge =
      [OIDAuthorizationRequest codeChallengeS256ForVerifier:codeVerifier];

  OIDAuthorizationRequest *request = [[OIDAuthorizationRequest alloc]
      initWithConfiguration:serviceConfiguration
                   clientId:clientId
               clientSecret:clientSecret
                      scope:[OIDScopeUtilities scopesWithArray:scopes]
                redirectURL:[NSURL URLWithString:redirectUrl]
               responseType:OIDResponseTypeCode
                      state:[OIDAuthorizationRequest generateState]
                      nonce:nonce != nil
                                ? nonce
                                : [OIDAuthorizationRequest generateState]
               codeVerifier:codeVerifier
              codeChallenge:codeChallenge
        codeChallengeMethod:OIDOAuthorizationRequestCodeChallengeMethodS256
       additionalParameters:additionalParameters];
  UIViewController *rootViewController = [self rootViewController];
  if (exchangeCode) {
    id<OIDExternalUserAgent> agent =
        [self userAgentWithViewController:rootViewController
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
    id<OIDExternalUserAgent> agent =
        [self userAgentWithViewController:rootViewController
                        externalUserAgent:externalUserAgent];
    return [OIDAuthorizationService
        presentAuthorizationRequest:request
                  externalUserAgent:agent
                           callback:^(OIDAuthorizationResponse
                                          *_Nullable authorizationResponse,
                                      NSError *_Nullable error) {
                             [self authorizationResponseCallback:
                                       authorizationResponse
                                                           error:error
                                                          result:result];
                           }];
  }
}

- (void)authorizationResponseCallback:
            (OIDAuthorizationResponse *_Nullable)response
                                error:(NSError *_Nullable)error
                               result:(FlutterResult)result {
  @try {
    if (response) {
      NSMutableDictionary *resultData = [[NSMutableDictionary alloc] init];
      [resultData setObject:response.additionalParameters
                     forKey:@"authorizationAdditionalParameters"];
      [resultData setObject:response.authorizationCode
                     forKey:@"authorizationCode"];
      [resultData setObject:response.request.codeVerifier
                     forKey:@"codeVerifier"];
      [resultData setObject:response.request.nonce forKey:@"nonce"];
      result(resultData);
    } else {
      [FlutterAppAuth
          finishWithError:AUTHORIZE_ERROR_CODE
                  message:[FlutterAppAuth formatMessageWithError:
                                              AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                           error:error]
                   result:result
                    error:error];
    }
  } @catch (NSException *e) {
    error = [NSError errorWithDomain:e.name
                                code:0
                            userInfo:@{
                              NSUnderlyingErrorKey : e,
                              NSDebugDescriptionErrorKey : e.userInfo ?: @{},
                              NSLocalizedFailureReasonErrorKey :
                                  (e.reason ?: @"Failed to process response")
                            }];
    [FlutterAppAuth
        finishWithError:AUTHORIZE_ERROR_CODE
                message:[FlutterAppAuth formatMessageWithError:
                                            AUTHORIZE_ERROR_MESSAGE_FORMAT
                                                         error:error]
                 result:result
                  error:error];
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

  UIViewController *rootViewController = [self rootViewController];
  id<OIDExternalUserAgent> externalUserAgent =
      [self userAgentWithViewController:rootViewController
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
                        NSMutableDictionary *resp =
                            [[NSMutableDictionary alloc] init];
                        [resp setObject:endSessionResponse.state
                                 forKey:@"state"];
                        result(resp);
                      }];
}

- (id<OIDExternalUserAgent>)
    userAgentWithViewController:(UIViewController *)rootViewController
              externalUserAgent:(NSNumber *)externalUserAgent {
  if ([externalUserAgent integerValue] == EphemeralASWebAuthenticationSession) {
    return [[OIDExternalUserAgentIOSNoSSO alloc]
        initWithPresentingViewController:rootViewController];
  }
  if ([externalUserAgent integerValue] == SafariViewController) {
    return [[OIDExternalUserAgentIOSSafariViewController alloc]
        initWithPresentingViewController:rootViewController];
  }
  return [[OIDExternalUserAgentIOS alloc]
      initWithPresentingViewController:rootViewController];
}

- (UIViewController *)rootViewController {
  if (@available(iOS 13, *)) {
    return [[UIApplication sharedApplication].windows
               filteredArrayUsingPredicate:[NSPredicate
                                               predicateWithBlock:^BOOL(
                                                   id window,
                                                   NSDictionary *bindings) {
                                                 return [window isKeyWindow];
                                               }]]
        .firstObject.rootViewController;
  }
  return [UIApplication sharedApplication].delegate.window.rootViewController;
}

@end
