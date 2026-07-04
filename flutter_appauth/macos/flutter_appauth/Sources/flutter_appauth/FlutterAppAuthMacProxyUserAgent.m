#import "FlutterAppAuthMacProxyUserAgent.h"

#import <AuthenticationServices/AuthenticationServices.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterAppAuthMacProxyUserAgent ()
    <ASWebAuthenticationPresentationContextProviding>
@end

@implementation FlutterAppAuthMacProxyUserAgent {
  NSWindow *_presentingWindow;
  NSString *_callbackScheme;
  NSString *_proxyRedirectUrl;
  BOOL _ephemeral;

  BOOL _externalUserAgentFlowInProgress;
  __weak id<OIDExternalUserAgentSession> _session;
  ASWebAuthenticationSession *_webAuthenticationSession;
}

- (instancetype)initWithPresentingWindow:(NSWindow *)presentingWindow
                          callbackScheme:(NSString *)callbackScheme
                        proxyRedirectUrl:(NSString *)proxyRedirectUrl
                               ephemeral:(BOOL)ephemeral {
  self = [super init];
  if (self) {
    _presentingWindow = presentingWindow;
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

  if (@available(macOS 10.15, *)) {
    if (_presentingWindow) {
      __weak FlutterAppAuthMacProxyUserAgent *weakSelf = self;
      ASWebAuthenticationSession *authenticationSession =
          [[ASWebAuthenticationSession alloc]
                    initWithURL:requestURL
              callbackURLScheme:callbackScheme
              completionHandler:^(NSURL *_Nullable callbackURL,
                                  NSError *_Nullable error) {
                __strong FlutterAppAuthMacProxyUserAgent *strongSelf = weakSelf;
                if (!strongSelf) {
                  return;
                }
                strongSelf->_webAuthenticationSession = nil;
                if (callbackURL) {
                  // Rewrite the custom-scheme callback URL to use
                  // proxyRedirectUrl's base so AppAuth's redirect URI
                  // validation passes.
                  NSURLComponents *proxyComponents =
                      [NSURLComponents componentsWithString:proxyRedirectUrl];
                  NSURLComponents *incomingComponents =
                      [NSURLComponents componentsWithURL:callbackURL
                                   resolvingAgainstBaseURL:NO];
                  proxyComponents.queryItems = incomingComponents.queryItems;
                  NSURL *rewrittenUrl = [proxyComponents URL];
                  [strongSelf->_session
                      resumeExternalUserAgentFlowWithURL:rewrittenUrl];
                } else {
                  NSError *agentError = [OIDErrorUtilities
                        errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
                      underlyingError:error
                          description:nil];
                  [strongSelf->_session
                      failExternalUserAgentFlowWithError:agentError];
                }
              }];

      authenticationSession.presentationContextProvider = self;
      if (_ephemeral) {
        authenticationSession.prefersEphemeralWebBrowserSession = YES;
      }
      _webAuthenticationSession = authenticationSession;
      BOOL started = [authenticationSession start];
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
  }

  // Fallback: open system browser (macOS < 10.15 or no presenting window).
  // URL rewriting for the callback is handled in handleGetURLEvent: via
  // _pendingProxyRedirectUrl.
  BOOL openedBrowser = [[NSWorkspace sharedWorkspace] openURL:requestURL];
  if (!openedBrowser) {
    [self cleanUp];
    NSError *browserError =
        [OIDErrorUtilities errorWithCode:OIDErrorCodeBrowserOpenError
                         underlyingError:nil
                             description:@"Unable to open the browser."];
    [session failExternalUserAgentFlowWithError:browserError];
  }
  return openedBrowser;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated
                               completion:(void (^)(void))completion {
  if (!_externalUserAgentFlowInProgress) {
    if (completion) completion();
    return;
  }
  ASWebAuthenticationSession *webAuthenticationSession = _webAuthenticationSession;
  [self cleanUp];
  if (webAuthenticationSession) {
    [webAuthenticationSession cancel];
  }
  if (completion) completion();
}

- (void)cleanUp {
  _webAuthenticationSession = nil;
  _session = nil;
  _externalUserAgentFlowInProgress = NO;
}

#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:
    (ASWebAuthenticationSession *)session API_AVAILABLE(macosx(10.15)) {
  return _presentingWindow;
}

@end

NS_ASSUME_NONNULL_END
