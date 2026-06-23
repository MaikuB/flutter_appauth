/*! @file OIDExternalUserAgentIOSNoSSO.m
    @brief OIDExternalUserAgentIOSNoSSO is a custom user agent based on the
   default user agent in the AppAuth iOS SDK found here:
           https://github.com/openid/AppAuth-iOS/blob/master/Source/iOS/OIDExternalUserAgentIOS.m
           This user agent allows setting `prefersEphemeralSession` flag on iOS
   13 or newer to avoid cookies being shared across the device.
 */

#import "OIDExternalUserAgentIOSNoSSO.h"

#import <AuthenticationServices/AuthenticationServices.h>
#import <SafariServices/SafariServices.h>

#if !TARGET_OS_MACCATALYST

NS_ASSUME_NONNULL_BEGIN

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
@interface OIDExternalUserAgentIOSNoSSO () <
    SFSafariViewControllerDelegate,
    ASWebAuthenticationPresentationContextProviding>
@end
#else
@interface OIDExternalUserAgentIOSNoSSO () <SFSafariViewControllerDelegate>
@end
#endif

@implementation OIDExternalUserAgentIOSNoSSO {
  UIViewController *_presentingViewController;
  BOOL _prefersEphemeralSession;
  NSURL *_redirectURL;

  BOOL _externalUserAgentFlowInProgress;
  __weak id<OIDExternalUserAgentSession> _session;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  __weak SFSafariViewController *_safariVC;
  SFAuthenticationSession *_authenticationVC;
  ASWebAuthenticationSession *_webAuthenticationVC;
#pragma clang diagnostic pop
}

- (nullable instancetype)init {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
  return [self initWithPresentingViewController:nil];
#pragma clang diagnostic pop
}

- (nullable instancetype)initWithPresentingViewController:
    (UIViewController *)presentingViewController {
  return [self initWithPresentingViewController:presentingViewController
                        prefersEphemeralSession:YES
                                    redirectURL:nil];
}

- (nullable instancetype)
    initWithPresentingViewController:
        (UIViewController *)presentingViewController
             prefersEphemeralSession:(BOOL)prefersEphemeralSession
                         redirectURL:(nullable NSURL *)redirectURL {
  self = [super init];
  if (self) {
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
    NSAssert(presentingViewController != nil,
             @"presentingViewController cannot be nil on iOS 13");
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000

    _presentingViewController = presentingViewController;
    _prefersEphemeralSession = prefersEphemeralSession;
    _redirectURL = redirectURL;
  }
  return self;
}

- (BOOL)presentExternalUserAgentRequest:(id<OIDExternalUserAgentRequest>)request
                                session:
                                    (id<OIDExternalUserAgentSession>)session {
  if (_externalUserAgentFlowInProgress) {
    // TODO: Handle errors as authorization is already in progress.
    return NO;
  }

  _externalUserAgentFlowInProgress = YES;
  _session = session;
  BOOL openedUserAgent = NO;
  NSURL *requestURL = [request externalUserAgentRequestURL];

  // iOS 12 and later, use ASWebAuthenticationSession
  if (@available(iOS 12.0, *)) {
    // ASWebAuthenticationSession doesn't work with guided access
    // (rdar://40809553)
    if (!UIAccessibilityIsGuidedAccessEnabled()) {
      __weak OIDExternalUserAgentIOSNoSSO *weakSelf = self;
      void (^completionHandler)(NSURL *_Nullable, NSError *_Nullable) = ^(
          NSURL *_Nullable callbackURL, NSError *_Nullable error) {
        __strong OIDExternalUserAgentIOSNoSSO *strongSelf = weakSelf;
        if (!strongSelf) {
          return;
        }
        strongSelf->_webAuthenticationVC = nil;
        if (callbackURL) {
          [strongSelf->_session resumeExternalUserAgentFlowWithURL:callbackURL];
        } else {
          NSError *safariError = [OIDErrorUtilities
                errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
              underlyingError:error
                  description:nil];
          [strongSelf->_session failExternalUserAgentFlowWithError:safariError];
        }
      };

      ASWebAuthenticationSession *authenticationVC = nil;
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 170400
      // On iOS 17.4 or newer, an `https` redirect URI requires the
      // `callbackWithHTTPSHost:path:` API; `callbackURLScheme:` only supports
      // custom schemes.
      if (@available(iOS 17.4, *)) {
        // Only use the https callback for a well-formed https redirect URL with
        // a host. Anything else (a custom scheme, or a nil/malformed redirect
        // URL such as an end-session request without a postLogoutRedirectUrl)
        // must fall through to the callbackURLScheme: path below. Guarding on
        // `scheme.length` is essential: `_redirectURL.scheme` is nil when
        // `_redirectURL` is nil, and `[nil caseInsensitiveCompare:@"https"]`
        // returns NSOrderedSame, which would otherwise pass a nil host/path to
        // the nonnull callbackWithHTTPSHost:path: and raise an exception.
        if (_redirectURL.scheme.length &&
            [_redirectURL.scheme caseInsensitiveCompare:@"https"] ==
                NSOrderedSame &&
            _redirectURL.host.length) {
          // callbackWithHTTPSHost:path: requires a nonnull path; treat a
          // host-only redirect URL as the root path.
          NSString *redirectPath =
              _redirectURL.path.length ? _redirectURL.path : @"/";
          ASWebAuthenticationSessionCallback *callback =
              [ASWebAuthenticationSessionCallback
                  callbackWithHTTPSHost:_redirectURL.host
                                   path:redirectPath];
          authenticationVC = [[ASWebAuthenticationSession alloc]
                    initWithURL:requestURL
                       callback:callback
              completionHandler:completionHandler];
        }
      }
#endif
      if (!authenticationVC) {
        NSString *redirectScheme = request.redirectScheme;
        authenticationVC =
            [[ASWebAuthenticationSession alloc] initWithURL:requestURL
                                          callbackURLScheme:redirectScheme
                                          completionHandler:completionHandler];
      }
#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
      if (@available(iOS 13.0, *)) {
        authenticationVC.presentationContextProvider = self;
      }
#endif
      _webAuthenticationVC = authenticationVC;
      if (@available(iOS 13.0, *)) {
        authenticationVC.prefersEphemeralWebBrowserSession =
            _prefersEphemeralSession;
      }
      openedUserAgent = [authenticationVC start];
    }
  }
  // iOS 11, use SFAuthenticationSession
  if (@available(iOS 11.0, *)) {
    // SFAuthenticationSession doesn't work with guided access (rdar://40809553)
    if (!openedUserAgent && !UIAccessibilityIsGuidedAccessEnabled()) {
      __weak OIDExternalUserAgentIOSNoSSO *weakSelf = self;
      NSString *redirectScheme = request.redirectScheme;
      SFAuthenticationSession *authenticationVC =
          [[SFAuthenticationSession alloc]
                    initWithURL:requestURL
              callbackURLScheme:redirectScheme
              completionHandler:^(NSURL *_Nullable callbackURL,
                                  NSError *_Nullable error) {
                __strong OIDExternalUserAgentIOSNoSSO *strongSelf = weakSelf;
                if (!strongSelf) {
                  return;
                }
                strongSelf->_authenticationVC = nil;
                if (callbackURL) {
                  [strongSelf->_session
                      resumeExternalUserAgentFlowWithURL:callbackURL];
                } else {
                  NSError *safariError = [OIDErrorUtilities
                        errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
                      underlyingError:error
                          description:@"User cancelled."];
                  [strongSelf->_session
                      failExternalUserAgentFlowWithError:safariError];
                }
              }];
      _authenticationVC = authenticationVC;
      openedUserAgent = [authenticationVC start];
    }
  }
  // iOS 9 and 10, use SFSafariViewController
  if (@available(iOS 9.0, *)) {
    if (!openedUserAgent && _presentingViewController) {
      SFSafariViewController *safariVC =
          [[SFSafariViewController alloc] initWithURL:requestURL];
      safariVC.delegate = self;
      _safariVC = safariVC;
      [_presentingViewController presentViewController:safariVC
                                              animated:YES
                                            completion:nil];
      openedUserAgent = YES;
    }
  }
  // iOS 8 and earlier, use mobile Safari
  if (!openedUserAgent) {
    openedUserAgent = [[UIApplication sharedApplication] openURL:requestURL];
  }

  if (!openedUserAgent) {
    [self cleanUp];
    NSError *safariError =
        [OIDErrorUtilities errorWithCode:OIDErrorCodeSafariOpenError
                         underlyingError:nil
                             description:@"Unable to open Safari."];
    [session failExternalUserAgentFlowWithError:safariError];
  }
  return openedUserAgent;
}

- (void)dismissExternalUserAgentAnimated:(BOOL)animated
                              completion:(void (^)(void))completion {
  if (!_externalUserAgentFlowInProgress) {
    // Ignore this call if there is no authorization flow in progress.
    if (completion)
      completion();
    return;
  }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wpartial-availability"
  SFSafariViewController *safariVC = _safariVC;
  SFAuthenticationSession *authenticationVC = _authenticationVC;
  ASWebAuthenticationSession *webAuthenticationVC = _webAuthenticationVC;
#pragma clang diagnostic pop

  [self cleanUp];

  if (webAuthenticationVC) {
    // dismiss the ASWebAuthenticationSession
    [webAuthenticationVC cancel];
    if (completion)
      completion();
  } else if (authenticationVC) {
    // dismiss the SFAuthenticationSession
    [authenticationVC cancel];
    if (completion)
      completion();
  } else if (safariVC) {
    // dismiss the SFSafariViewController
    [safariVC dismissViewControllerAnimated:YES completion:completion];
  } else {
    if (completion)
      completion();
  }
}

- (void)cleanUp {
  // The weak references to |_safariVC| and |_session| are set to nil to avoid
  // accidentally using them while not in an authorization flow.
  _safariVC = nil;
  _authenticationVC = nil;
  _webAuthenticationVC = nil;
  _session = nil;
  _externalUserAgentFlowInProgress = NO;
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(SFSafariViewController *)controller
    NS_AVAILABLE_IOS(9.0) {
  if (controller != _safariVC) {
    // Ignore this call if the safari view controller do not match.
    return;
  }
  if (!_externalUserAgentFlowInProgress) {
    // Ignore this call if there is no authorization flow in progress.
    return;
  }
  id<OIDExternalUserAgentSession> session = _session;
  [self cleanUp];
  NSError *error = [OIDErrorUtilities
        errorWithCode:OIDErrorCodeUserCanceledAuthorizationFlow
      underlyingError:nil
          description:@"No external user agent flow in progress."];
  [session failExternalUserAgentFlowWithError:error];
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000
#pragma mark - ASWebAuthenticationPresentationContextProviding

- (ASPresentationAnchor)presentationAnchorForWebAuthenticationSession:
    (ASWebAuthenticationSession *)session API_AVAILABLE(ios(13.0)) {
  return _presentingViewController.view.window;
}
#endif // __IPHONE_OS_VERSION_MAX_ALLOWED >= 130000

@end

NS_ASSUME_NONNULL_END

#endif // !TARGET_OS_MACCATALYST
