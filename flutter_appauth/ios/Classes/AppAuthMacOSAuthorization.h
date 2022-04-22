#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#endif

#import <AppAuth/AppAuth.h>
#import "FlutterAppAuth.h"

NS_ASSUME_NONNULL_BEGIN

@interface AppAuthMacOSAuthorization : AppAuthAuthorization

@end

NS_ASSUME_NONNULL_END
