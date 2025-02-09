#import "./include/flutter_appauth/FlutterAppauthPlugin.h"

#if TARGET_OS_OSX
#import "AppAuthMacOSAuthorization.h"
#else
#import "AppAuthIOSAuthorization.h"
#endif

#ifdef SWIFT_PACKAGE
@import AppAuth;
#else
#import <AppAuth/AppAuth.h>
#endif

@interface FlutterAppauthPlugin ()

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession>
    currentAuthorizationFlow;

@end
