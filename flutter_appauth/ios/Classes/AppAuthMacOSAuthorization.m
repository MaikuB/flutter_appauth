#import "AppAuthMacOSAuthorization.h"

@implementation AppAuthMacOSAuthorization

- (id<OIDExternalUserAgentSession>)performAuthorization:(OIDServiceConfiguration *)serviceConfiguration clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret scopes:(NSArray *)scopes redirectUrl:(NSString*)redirectUrl additionalParameters:(NSDictionary *)additionalParameters preferEphemeralSession:(BOOL)preferEphemeralSession result:(FlutterResult)result exchangeCode:(BOOL)exchangeCode {
  OIDAuthorizationRequest *request =
  [[OIDAuthorizationRequest alloc] initWithConfiguration:serviceConfiguration
                                                clientId:clientId
                                            clientSecret:clientSecret
                                                  scopes:scopes
                                             redirectURL:[NSURL URLWithString:redirectUrl]
                                            responseType:OIDResponseTypeCode
                                    additionalParameters:additionalParameters];
  if(exchangeCode) {
#if TARGET_OS_OSX
      NSObject<OIDExternalUserAgent> *agent = [OIDExternalUserAgentMac alloc];
#else
      NSObject<OIDExternalUserAgent> *agent = [OIDExternalUserAgentIOS alloc];
#endif

      return [OIDAuthState authStateByPresentingAuthorizationRequest:request externalUserAgent:agent callback:^(OIDAuthState *_Nullable authState,
                 NSError *_Nullable error) {
          if(authState) {
              result([FlutterAppAuth processResponses:authState.lastTokenResponse authResponse:authState.lastAuthorizationResponse]);

          } else {
              [FlutterAppAuth finishWithError:AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE message:[FlutterAppAuth formatMessageWithError:AUTHORIZE_ERROR_MESSAGE_FORMAT error:error] result:result];
          }
      }];
  } else {
#if TARGET_OS_OSX
      NSObject<OIDExternalUserAgent> *agent = [OIDExternalUserAgentMac alloc];
#else
      NSObject<OIDExternalUserAgent> *agent = [OIDExternalUserAgentIOS alloc];
#endif
      return [OIDAuthorizationService presentAuthorizationRequest:request externalUserAgent:agent callback:^(OIDAuthorizationResponse *_Nullable authorizationResponse, NSError *_Nullable error) {
          if(authorizationResponse) {
              NSMutableDictionary *processedResponse = [[NSMutableDictionary alloc] init];
              [processedResponse setObject:authorizationResponse.additionalParameters forKey:@"authorizationAdditionalParameters"];
              [processedResponse setObject:authorizationResponse.authorizationCode forKey:@"authorizationCode"];
              [processedResponse setObject:authorizationResponse.request.codeVerifier forKey:@"codeVerifier"];
              result(processedResponse);
          } else {
              [FlutterAppAuth finishWithError:AUTHORIZE_ERROR_CODE message:[FlutterAppAuth formatMessageWithError:AUTHORIZE_ERROR_MESSAGE_FORMAT error:error] result:result];
          }
      }];
  }
}

- (id<OIDExternalUserAgentSession>)performEndSessionRequest:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(EndSessionRequestParameters *)requestParameters result:(FlutterResult)result {
  return nil;
}

@end
