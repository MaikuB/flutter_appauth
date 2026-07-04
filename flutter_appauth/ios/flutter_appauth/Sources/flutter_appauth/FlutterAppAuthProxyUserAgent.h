#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/// A custom OIDExternalUserAgent for the proxy redirect URL use case.
///
/// When an OAuth server only allows HTTPS redirect URIs but the app uses a
/// custom-scheme deep link, this user agent:
///   1. Starts an ASWebAuthenticationSession with `callbackURLScheme` set to
///      the custom scheme (so the OS intercepts the deep link).
///   2. Rewrites the returned custom-scheme callback URL to use the
///      proxyRedirectUrl's base before passing it to AppAuth, so AppAuth's
///      validation (which expects the proxy https URL) succeeds.
@interface FlutterAppAuthProxyUserAgent
    : NSObject <OIDExternalUserAgent>

- (instancetype)initWithPresentingViewController:
                    (UIViewController *)presentingViewController
                                  callbackScheme:(NSString *)callbackScheme
                                proxyRedirectUrl:(NSString *)proxyRedirectUrl
                                       ephemeral:(BOOL)ephemeral;

@end

NS_ASSUME_NONNULL_END
