#import "FlutterAppAuth.h"
#import "OIDExternalUserAgentIOSNoSSO.h"
#import "OIDExternalUserAgentIOSSafariViewController.h"
#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppAuthIOSAuthorization : AppAuthAuthorization

@end

NS_ASSUME_NONNULL_END
