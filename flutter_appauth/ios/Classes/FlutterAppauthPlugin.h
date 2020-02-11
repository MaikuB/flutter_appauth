#import <Flutter/Flutter.h>

@protocol OIDExternalUserAgentSession;

@interface FlutterAppauthPlugin : NSObject<FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end
