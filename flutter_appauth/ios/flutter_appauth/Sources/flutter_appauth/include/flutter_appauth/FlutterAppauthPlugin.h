#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import "AppAuthMacOSAuthorization.h"
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import "AppAuthIOSAuthorization.h"
#import <Flutter/Flutter.h>
#endif

#import <AppAuth/AppAuth.h>

@interface FlutterAppauthPlugin : NSObject <FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession>
    currentAuthorizationFlow;

@end
