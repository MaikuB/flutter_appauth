#import <Flutter/Flutter.h>
#import "OIDExternalUserAgentIOSSafariViewController.h"
#import "OIDExternalUserAgentIOSEphemeral.h"

@protocol OIDExternalUserAgentSession;

@interface FlutterAppauthPlugin : NSObject <FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end
