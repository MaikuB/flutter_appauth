#import "FlutterAppauthPlugin.h"
#import "AppAuth.h"

@interface ArgumentProcessor : NSObject
+ (id _Nullable)processArgumentValue:(NSDictionary *)arguments withKey:(NSString *)key;
@end

@implementation ArgumentProcessor

+ (id _Nullable)processArgumentValue:(NSDictionary *)arguments withKey:(NSString *)key {
    return [arguments objectForKey:key] != [NSNull null] ? arguments[key] : nil;
}

@end

@interface TokenRequestParameters : NSObject
@property(nonatomic, strong) NSString *clientId;
@property(nonatomic, strong) NSString *clientSecret;
@property(nonatomic, strong) NSString *issuer;
@property(nonatomic, strong) NSString *grantType;
@property(nonatomic, strong) NSString *discoveryUrl;
@property(nonatomic, strong) NSString *redirectUrl;
@property(nonatomic, strong) NSString *refreshToken;
@property(nonatomic, strong) NSArray *scopes;
@property(nonatomic, strong) NSDictionary *serviceConfigurationParameters;
@property(nonatomic, strong) NSDictionary *additionalParameters;

@end

@implementation TokenRequestParameters
- (void)processArguments:(NSDictionary *)arguments {
    _clientId = [ArgumentProcessor processArgumentValue:arguments withKey:@"clientId"];
    _clientSecret = [ArgumentProcessor processArgumentValue:arguments withKey:@"clientSecret"];
    _issuer = [ArgumentProcessor processArgumentValue:arguments withKey:@"issuer"];
    _discoveryUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"discoveryUrl"];
    _redirectUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"redirectUrl"];
    _refreshToken = [ArgumentProcessor processArgumentValue:arguments withKey:@"refreshToken"];
    _grantType = [ArgumentProcessor processArgumentValue:arguments withKey:@"grantType"];
    _scopes = [ArgumentProcessor processArgumentValue:arguments withKey:@"scopes"];
    _serviceConfigurationParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"serviceConfiguration"];
    _additionalParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"additionalParameters"];
}

- (id)initWithArguments:(NSDictionary *)arguments {
    [self processArguments:arguments];
    return self;
}

@end

@interface AuthorizationTokenRequestParameters : TokenRequestParameters
@property(nonatomic, strong) NSString *loginHint;
@end

@implementation AuthorizationTokenRequestParameters
- (id)initWithArguments:(NSDictionary *)arguments {
    [super processArguments:arguments];
    _loginHint = [ArgumentProcessor processArgumentValue:arguments withKey:@"loginHint"];
    return self;
}
@end

@implementation FlutterAppauthPlugin

FlutterMethodChannel* channel;
NSString *const AUTHORIZE_AND_EXCHANGE_TOKEN_METHOD = @"authorizeAndExchangeToken";
NSString *const TOKEN_METHOD = @"token";
NSString *const DISCOVERY_ERROR_CODE = @"discovery_failed";
NSString *const TOKEN_ERROR_CODE = @"token_failed";
NSString *const DISCOVERY_ERROR_MESSAGE_FORMAT = @"Error retrieving discovery document: %@";
NSString *const TOKEN_ERROR_MESSAGE = @"Failed to exchange token";



+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:@"crossingthestreams.io/flutter_appauth"
               binaryMessenger:[registrar messenger]];
    FlutterAppauthPlugin* instance = [[FlutterAppauthPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([AUTHORIZE_AND_EXCHANGE_TOKEN_METHOD isEqualToString:call.method]) {
        [self handleAuthorizeMethodCall:[call arguments] result:result];
    } else if([TOKEN_METHOD isEqualToString:call.method]) {
        [self handleTokenMethodCall:[call arguments] result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)handleAuthorizeMethodCall:(NSDictionary*)arguments result:(FlutterResult)result {
    AuthorizationTokenRequestParameters *requestParameters = [[AuthorizationTokenRequestParameters alloc] initWithArguments:arguments];
    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration =
        [[OIDServiceConfiguration alloc]
         initWithAuthorizationEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"authorizationEndpoint"]]
         tokenEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"tokenEndpoint"]]];
        [self performAuthorization:serviceConfiguration clientId:requestParameters.clientId clientSecret:requestParameters.clientSecret scopes:requestParameters.scopes redirectUrl:requestParameters.redirectUrl additionalParameters:requestParameters.additionalParameters result:result];
    } else if (requestParameters.discoveryUrl) {
        NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
        
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                                                  completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                               NSError *_Nullable error) {
                                                                      
                                                                      if (!configuration) {
                                                                          [self finishWithDiscoveryError:error result:result];
                                                                          return;
                                                                      }
                                                                      
                                                                      [self performAuthorization:configuration clientId:requestParameters.clientId clientSecret:requestParameters.clientSecret scopes:requestParameters.scopes redirectUrl:requestParameters.redirectUrl additionalParameters:requestParameters.additionalParameters result:result];
                                                                  }];
    } else {
        NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
        [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuerUrl
                                                            completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                         NSError *_Nullable error) {
                                                                
                                                                if (!configuration) {
                                                                    [self finishWithDiscoveryError:error result:result];
                                                                    return;
                                                                }
                                                                
                                                                [self performAuthorization:configuration clientId:requestParameters.clientId clientSecret:requestParameters.clientSecret scopes:requestParameters.scopes redirectUrl:requestParameters.redirectUrl additionalParameters:requestParameters.additionalParameters result:result];
                                                            }];
    }
    
    
}

- (void)performAuthorization:(OIDServiceConfiguration *)serviceConfiguration clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret scopes:(NSArray *)scopes redirectUrl:(NSString*)redirectUrl additionalParameters:(NSDictionary *)additionalParameters result:(FlutterResult)result {
    OIDAuthorizationRequest *request =
    [[OIDAuthorizationRequest alloc] initWithConfiguration:serviceConfiguration
                                                  clientId:clientId
                                              clientSecret:clientSecret
                                                    scopes:scopes
                                               redirectURL:[NSURL URLWithString:redirectUrl]
                                              responseType:OIDResponseTypeCode
                                      additionalParameters:additionalParameters];
    UIViewController *rootViewController =
    [UIApplication sharedApplication].delegate.window.rootViewController;
    _currentAuthorizationFlow = [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                                               presentingViewController: rootViewController
                                                                               callback:^(OIDAuthState *_Nullable authState,
                                                                                          NSError *_Nullable error) {
                                                                                   if(authState) {
                                                                                       result([self processResponses:authState.lastTokenResponse authResponse:authState.lastAuthorizationResponse]);
                                                                                   } else {
                                                                                       
                                                                                   }
                                                                               }];
}

- (void)finishWithDiscoveryError:(NSError * _Nullable)error result:(FlutterResult)result {
    NSString *message = [NSString stringWithFormat:DISCOVERY_ERROR_MESSAGE_FORMAT, [error localizedDescription]];
    result([FlutterError errorWithCode:DISCOVERY_ERROR_CODE message:message details:nil]);
}

-(void)handleTokenMethodCall:(NSDictionary*)arguments result:(FlutterResult)result {
    TokenRequestParameters *requestParameters = [[TokenRequestParameters alloc] initWithArguments:arguments];
    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration =
        [[OIDServiceConfiguration alloc]
         initWithAuthorizationEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"authorizationEndpoint"]]
         tokenEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"tokenEndpoint"]]];
        [self performTokenRequest:serviceConfiguration requestParameters:requestParameters result:result];
    } else if (requestParameters.discoveryUrl) {
        NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
        
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                                                  completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                               NSError *_Nullable error) {
                                                                      
                                                                      if (!configuration) {
                                                                          [self finishWithDiscoveryError:error result:result];
                                                                          return;
                                                                      }
                                                                      
                                                                      [self performTokenRequest:configuration requestParameters:requestParameters result:result];
                                                                  }];
    } else {
        NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
        [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuerUrl
                                                            completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                         NSError *_Nullable error) {
                                                                
                                                                if (!configuration) {
                                                                    [self finishWithDiscoveryError:error result:result];
                                                                    return;
                                                                }
                                                                
                                                                [self performTokenRequest:configuration requestParameters:requestParameters result:result];
                                                            }];
    }
    
}

- (void)performTokenRequest:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(TokenRequestParameters *)requestParameters result:(FlutterResult)result {
    OIDTokenRequest *tokenRequest =
    [[OIDTokenRequest alloc] initWithConfiguration:serviceConfiguration
                                         grantType:requestParameters.grantType
                                 authorizationCode:nil
                                       redirectURL:[NSURL URLWithString:requestParameters.redirectUrl]
                                          clientID:requestParameters.clientId
                                      clientSecret:requestParameters.clientSecret
                                            scopes:requestParameters.scopes
                                      refreshToken:requestParameters.refreshToken
                                      codeVerifier:nil
                              additionalParameters:requestParameters.additionalParameters];
    [OIDAuthorizationService performTokenRequest:tokenRequest
                                        callback:^(OIDTokenResponse *_Nullable response,
                                                   NSError *_Nullable error) {
                                            if (response) {
                                                result([self processResponses:response authResponse:nil]);                                           } else {
                                                    result(nil);
                                                }
                                        }];
}

- (NSMutableDictionary *)processResponses:(OIDTokenResponse*) tokenResponse authResponse:(OIDAuthorizationResponse*) authResponse {
    NSMutableDictionary *processedResponses = [[NSMutableDictionary alloc] init];
    if(tokenResponse.accessToken) {
        [processedResponses setValue:tokenResponse.accessToken forKey:@"accessToken"];
    }
    if(tokenResponse.accessTokenExpirationDate) {
        [processedResponses setValue:[[NSNumber alloc] initWithDouble:[tokenResponse.accessTokenExpirationDate timeIntervalSince1970] * 1000] forKey:@"accessTokenExpirationTime"];
    }
    if(authResponse && authResponse.additionalParameters) {
        [processedResponses setObject:authResponse.additionalParameters forKey:@"authorizationAdditionalParameters"];
    }
    if(tokenResponse.additionalParameters) {
        [processedResponses setObject:tokenResponse.additionalParameters forKey:@"tokenAdditionalParameters"];
    }
    if(tokenResponse.idToken) {
        [processedResponses setValue:tokenResponse.idToken forKey:@"idToken"];
    }
    if(tokenResponse.refreshToken) {
        [processedResponses setValue:tokenResponse.refreshToken forKey:@"refreshToken"];
    }
    if(tokenResponse.tokenType) {
        [processedResponses setValue:tokenResponse.tokenType forKey:@"tokenType"];
    }
    
    return processedResponses;
}


- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if ([_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
        _currentAuthorizationFlow = nil;
        return YES;
    }
    
    return NO;
}
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {
    return [self application:application openURL:url options:@{}];
}
@end
