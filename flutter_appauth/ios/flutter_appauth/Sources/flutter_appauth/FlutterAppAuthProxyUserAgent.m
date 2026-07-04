#import "FlutterAppAuthProxyUserAgent.h"

#import <AuthenticationServices/AuthenticationServices.h>

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
@interface FlutterAppAuthProxyUserAgent ()
    <ASWebAuthenticationPresentationContextProviding>
@end
#endif

@implementation FlutterAppAuthProxyUserAgent {
  UIViewController *_presentingViewController;
  NSString *_callbackScheme;
  NSString *_proxyRedirectUrl;
  BOOL _ephemeral;

  BOOL _externalUserAgentFlowInProgress;
  __weak id<OIDExternalUserAgentSession> _session;
  ASWebAuthenticationSession *_webAuthenticationVC;
}

- (instancetype)initWithPresentingViewController:
                    (UIViewController *)presentingViewController
                                  callbackScheme:(NSString *)callbackScheme
                                proxyRedirectUrl:(NSString *)proxyRedirectUrl
                                       ephemeral:(BOOL)ephemeral {
  self = [super init];
  if (self) {
    _presentingViewController = presentingViewController;
    _callbackScheme = callbackScheme;
    _proxyRedirectUrl = proxyRedirectUrl;
    _ephemeral = ephemeral;
  }
  return self;
}

- (BOOL)presentExternalUserAgentRequest:(id<OIDExternalUserAgentRequest>)request
                                 session:(id<OIDExternalUserAgentSession>)session {
  if (_externalUserAgentFlowInProgress) {
    return NO;
  }

  _externalUserAgentFlowInProgress = YES;
  _session = session;

  NSURL *requestURL = [request externalUserAgentRequestURL];
  NSString *callbackScheme = _callbackScheme;
  NSString *proxyRedirectUrl = _proxyRedirectUrl;

  __weak FlutterAppAuthProxyUserAgent *weakSelf = self;
  ASWebAuthenticationSession *authenticationVC = [[ASWebAuthenticationSession alloc]
            initWithURL:requestURL
      callbackURLScheme:callbackScheme
      completionHandler:^(NSURL *_Nullable callbackURL, NSError *_Nullable error) {
        __strong FlutterAppAuthProxyUserAgent *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        strongSelf->_webAuthenticationVC = nil;
        if (callbackURL) {
          // Rewrite the custom-scheme callback URL to use proxyRedirectUrl's
          // base so AppAuth's redirect URI validation passes.
          NSURLComponents *proxyComponents =
              [NSURLComponents componentsWithString:proxyRedirectUrl];
          NSURLComponents *incomingComponents =
              [NSURLComponents componentsWithURL:callbackURL
                           resolvingAgainstBaseURL:NO];
          proxyComponents.queryItems = incomingComponents.queryItems;
          NSURL *rewrittenUrl = [proxyComponents URL];
          [strongSelf->_session resumeExternalUserAgentFlowWithURL:rewrittenUrl];
        } else {
          NSError *agentError = [OIDErrorUtilities
                errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
              underlyingError:error
                  description:nil];
          [strongSelf->_session failExternalUserAgentFlowWithError:agentError];
        }
      }];

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
  if (@available(iOS 13.0, *)) {
    authenticationVC.presentationContextProvider = self;
    if (_ephemeral) {
      authenticationVC.prefersEphemeralWebBrowserSession = YES;
    }
  }
#endif

  _webAuthenticationVC = authenticationVC;
  BOOL started = [authenticationVC start];
  if (!started) {
    [self cleanUp];
    NSError *startError = [OIDErrorUtilities
          errorWithCode:OIDErrorCodeSafariOpenError
        underlyingError:nil
            description:@"Unable to start ASWebAuthenticationSession."];
    [session failExternalUserAgentFlowWithError:startError];
  }
  return started;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated
                               completion:(void (^)(void))completion {
  if (!_externalUserAgentFlowInProgress) {
    if (completion) completion();
    return;
  }
  ASWebAuthenticationSession *webAuthenticationVC = _webAuthenticationVC;
  [self cleanUp];
  if (webAuthenticationVC) {
    [webAuthenticationVC cancel];
  }
  if (completion) completion();
}

- (void)cleanUp {
  _webAuthenticationVC = nil;
  _session = nil;
  _externalUserAgentFlowInProgress = NO;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:
    (ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0)) {
  return _presentingViewController.view.window;
}
#endif

@end

NS_ASSUME_NONNULL_END
