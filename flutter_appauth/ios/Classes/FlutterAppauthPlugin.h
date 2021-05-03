#import <Flutter/Flutter.h>
#import <AppAuth/AppAuth.h>

@protocol OIDExternalUserAgentSession;

@interface FlutterAppauthPlugin : NSObject <FlutterPlugin>

@property(nonatomic, strong, nullable) id<OIDExternalUserAgentSession> currentAuthorizationFlow;

@end
