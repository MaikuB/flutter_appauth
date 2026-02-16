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
  UIViewController *presentingViewController = [self topMostViewController];
  if (exchangeCode) {
    id<OIDExternalUserAgent> agent =
        [self userAgentWithViewController:presentingViewController
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
        [self userAgentWithViewController:presentingViewController
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
                                      forKey:
                                          @"authorizationAdditionalParameters"];
                               [processedResponse
                                   setObject:authorizationResponse
                                                 .authorizationCode
                                      forKey:@"authorizationCode"];
                               [processedResponse
                                   setObject:authorizationResponse.request
                                                 .codeVerifier
                                      forKey:@"codeVerifier"];
                               [processedResponse
                                   setObject:authorizationResponse.request.nonce
                                      forKey:@"nonce"];
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

  UIViewController *presentingViewController = [self topMostViewController];
  id<OIDExternalUserAgent> externalUserAgent =
      [self userAgentWithViewController:presentingViewController
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
    userAgentWithViewController:(UIViewController *)presentingViewController
              externalUserAgent:(NSNumber *)externalUserAgent {
  if ([externalUserAgent integerValue] == EphemeralASWebAuthenticationSession) {
    return [[OIDExternalUserAgentIOSNoSSO alloc]
        initWithPresentingViewController:presentingViewController];
  }
  if ([externalUserAgent integerValue] == SafariViewController) {
    return [[OIDExternalUserAgentIOSSafariViewController alloc]
        initWithPresentingViewController:presentingViewController];
  }
  return [[OIDExternalUserAgentIOS alloc]
      initWithPresentingViewController:presentingViewController];
}

- (UIViewController *)topMostViewController {
    return [self topMostViewControllerWithRootViewController:[self rootViewController]];
}

- (UIViewController *)topMostViewControllerWithRootViewController:(UIViewController *)viewController {
    if (viewController.presentedViewController && !viewController.presentedViewController.isBeingDismissed) {
        return [self topMostViewControllerWithRootViewController:viewController.presentedViewController];
    }
    if ([viewController isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tabBarController = (UITabBarController *)viewController;
        return [self topMostViewControllerWithRootViewController:tabBarController.selectedViewController];
    }
    if ([viewController isKindOfClass:[UINavigationController class]]) {
        UINavigationController *navController = (UINavigationController *)viewController;
        return [self topMostViewControllerWithRootViewController:navController.visibleViewController];
    }

    return viewController;
}

- (UIViewController *)rootViewController {
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive && [scene isKindOfClass:[UIWindowScene class]]) {
                UIWindowScene *windowScene = (UIWindowScene *)scene;
                for (UIWindow *window in windowScene.windows) {
                    if (window.isKeyWindow) {
                        return window.rootViewController;
                    }
                }
            }
        }
        return nil;
    } else {
        return [UIApplication sharedApplication].delegate.window.rootViewController;
    }
}

@end
