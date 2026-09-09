#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

NS_ASSUME_NONNULL_BEGIN

/// A macOS-specific OIDExternalUserAgent for the proxy redirect URL use case.
///
/// Mirrors FlutterAppAuthProxyUserAgent (iOS) but uses NSWindow for the
/// ASWebAuthenticationSession presentation context.
@interface FlutterAppAuthMacProxyUserAgent
    : NSObject <OIDExternalUserAgent>

- (instancetype)initWithPresentingWindow:(NSWindow *)presentingWindow
                          callbackScheme:(NSString *)callbackScheme
                        proxyRedirectUrl:(NSString *)proxyRedirectUrl
                               ephemeral:(BOOL)ephemeral;

@end

NS_ASSUME_NONNULL_END
