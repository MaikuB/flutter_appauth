#import <TargetConditionals.h>

#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#import "AppAuthMacOSAuthorization.h"
#else
#import <Flutter/Flutter.h>
#import "AppAuthIOSAuthorization.h"
#endif

#import <AppAuth/AppAuth.h>

@interface FlutterAppauthPlugin : NSObject<FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end
