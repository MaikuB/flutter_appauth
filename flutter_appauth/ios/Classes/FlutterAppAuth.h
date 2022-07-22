#if TARGET_OS_OSX
#import <FlutterMacOS/FlutterMacOS.h>
#else
#import <Flutter/Flutter.h>
#endif

#import <AppAuth/AppAuth.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface FlutterAppAuth : NSObject

+ (NSMutableDictionary *)processResponses:(OIDTokenResponse*) tokenResponse authResponse:(OIDAuthorizationResponse* _Nullable) authResponse;
+ (void)finishWithError:(NSString *)errorCode message:(NSString *)message  result:(FlutterResult)result;
+ (NSString *) formatMessageWithError:(NSString *)messageFormat error:(NSError * _Nullable)error;

@end

static NSString *const AUTHORIZE_METHOD = @"authorize";
static NSString *const AUTHORIZE_AND_EXCHANGE_CODE_METHOD = @"authorizeAndExchangeCode";
static NSString *const TOKEN_METHOD = @"token";
static NSString *const END_SESSION_METHOD = @"endSession";
static NSString *const AUTHORIZE_ERROR_CODE = @"authorize_failed";
static NSString *const AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE = @"authorize_and_exchange_code_failed";
static NSString *const DISCOVERY_ERROR_CODE = @"discovery_failed";
static NSString *const TOKEN_ERROR_CODE = @"token_failed";
static NSString *const END_SESSION_ERROR_CODE = @"end_session_failed";
static NSString *const DISCOVERY_ERROR_MESSAGE_FORMAT = @"Error retrieving discovery document: %@";
static NSString *const TOKEN_ERROR_MESSAGE_FORMAT = @"Failed to get token: %@";
static NSString *const AUTHORIZE_ERROR_MESSAGE_FORMAT = @"Failed to authorize: %@";
static NSString *const END_SESSION_ERROR_MESSAGE_FORMAT = @"Failed to end session: %@";

@interface EndSessionRequestParameters : NSObject
@property(nonatomic, strong) NSString *idTokenHint;
@property(nonatomic, strong) NSString *postLogoutRedirectUrl;
@property(nonatomic, strong) NSString *state;
@property(nonatomic, strong) NSString *issuer;
@property(nonatomic, strong) NSString *discoveryUrl;
@property(nonatomic, strong) NSDictionary *serviceConfigurationParameters;
@property(nonatomic, strong) NSDictionary *additionalParameters;
@property(nonatomic, readwrite) BOOL preferEphemeralSession;
@end

@interface AppAuthAuthorization : NSObject

- (id<OIDExternalUserAgentSession>)performAuthorization:(OIDServiceConfiguration *)serviceConfiguration clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret scopes:(NSArray *)scopes redirectUrl:(NSString*)redirectUrl additionalParameters:(NSDictionary *)additionalParameters preferEphemeralSession:(BOOL)preferEphemeralSession result:(FlutterResult)result exchangeCode:(BOOL)exchangeCode nonce:(NSString*)nonce;

- (id<OIDExternalUserAgentSession>)performEndSessionRequest:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(EndSessionRequestParameters *)requestParameters result:(FlutterResult)result;

@end

NS_ASSUME_NONNULL_END
