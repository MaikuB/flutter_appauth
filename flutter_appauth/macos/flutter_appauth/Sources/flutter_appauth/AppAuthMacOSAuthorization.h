#import "FlutterAppAuth.h"
#import "OIDExternalUserAgentMacNoSSO.h"
#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif
#import <FlutterMacOS/FlutterMacOS.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppAuthMacOSAuthorization : AppAuthAuthorization

@end

NS_ASSUME_NONNULL_END
