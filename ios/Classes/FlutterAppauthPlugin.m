#import "FlutterAppauthPlugin.h"
#import "AppAuth.h"

@interface RequestParameters : NSObject

@property(nonatomic, strong) NSString *clientId;
@property(nonatomic, strong) NSString *clientSecret;
@property(nonatomic, strong) NSString *issuer;
@property(nonatomic, strong) NSString *discoveryUrl;
@property(nonatomic, strong) NSString *loginHint;
@property(nonatomic, strong) NSString *redirectUrl;
@property(nonatomic, strong) NSString *refreshToken;
@property(nonatomic, strong) NSArray *scopes;
@property(nonatomic, strong) NSDictionary *serviceConfigurationParameters;
@property(nonatomic, strong) NSDictionary *additionalParameters;

@end

@implementation RequestParameters
@end

@implementation FlutterAppauthPlugin

FlutterMethodChannel* channel;
NSString *const AUTHORIZE_METHOD = @"authorize";
NSString *const REFRESH_METHOD = @"refresh";

id<OIDExternalUserAgentSession> currentAuthorizationFlow;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:@"crossingthestreams.io/flutter_appauth"
               binaryMessenger:[registrar messenger]];
    FlutterAppauthPlugin* instance = [[FlutterAppauthPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    [registrar addApplicationDelegate:instance];
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([AUTHORIZE_METHOD isEqualToString:call.method]) {
        [self handleAuthorize:[call arguments] result:result];
    } else if([REFRESH_METHOD isEqualToString:call.method]) {
        [self handleRefresh:[call arguments] result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

-(void)handleAuthorize:(NSDictionary*)arguments result:(FlutterResult)result {
    RequestParameters *requestParameters = [self processCallArguments:arguments];
    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration =
        [[OIDServiceConfiguration alloc]
         initWithAuthorizationEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"authorizationEndpoint"]]
         tokenEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"tokenEndpoint"]]];
        [self performAuthorization:serviceConfiguration requestParameters:requestParameters result:result];
    } else if (requestParameters.discoveryUrl) {
        NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
        
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                                                  completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                               NSError *_Nullable error) {
                                                                      
                                                                      if (!configuration) {
                                                                          NSLog(@"Error retrieving discovery document: %@",
                                                                                [error localizedDescription]);
                                                                          result(nil);
                                                                          return;
                                                                      }
                                                                      
                                                                      [self performAuthorization:configuration requestParameters:requestParameters result:result];
                                                                  }];
    } else {
        NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
        [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuerUrl
                                                            completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                         NSError *_Nullable error) {
                                                                
                                                                if (!configuration) {
                                                                    NSLog(@"Error retrieving discovery document: %@",
                                                                          [error localizedDescription]);
                                                                    result(nil);
                                                                    return;
                                                                }
                                                                
                                                                [self performAuthorization:configuration requestParameters:requestParameters result:result];
                                                            }];
    }
    
    
}

- (void)performAuthorization:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(RequestParameters *)requestParameters result:(FlutterResult)result {
    OIDAuthorizationRequest *request =
    [[OIDAuthorizationRequest alloc] initWithConfiguration:serviceConfiguration
                                                  clientId:requestParameters.clientId
                                              clientSecret:requestParameters.clientSecret
                                                    scopes:requestParameters.scopes
                                               redirectURL:[NSURL URLWithString:requestParameters.redirectUrl]
                                              responseType:OIDResponseTypeCode
                                      additionalParameters:requestParameters.additionalParameters];
    UIViewController *rootViewController =
    [UIApplication sharedApplication].delegate.window.rootViewController;
    currentAuthorizationFlow = [OIDAuthState authStateByPresentingAuthorizationRequest:request
                                                              presentingViewController: rootViewController
                                                                              callback:^(OIDAuthState *_Nullable authState,
                                                                                         NSError *_Nullable error) {
                                                                                  if(authState) {
                                                                                      result([self processResponses:authState.lastTokenResponse authResponse:authState.lastAuthorizationResponse]);
                                                                                  } else {
                                                                                      
                                                                                  }
                                                                              }];
}

-(void)handleRefresh:(NSDictionary*)arguments result:(FlutterResult)result {
    RequestParameters *requestParameters = [self processCallArguments:arguments];
    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration =
        [[OIDServiceConfiguration alloc]
         initWithAuthorizationEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"authorizationEndpoint"]]
         tokenEndpoint:[NSURL URLWithString:requestParameters.serviceConfigurationParameters[@"tokenEndpoint"]]];
        [self performRefresh:serviceConfiguration requestParameters:requestParameters result:result];
    } else if (requestParameters.discoveryUrl) {
        NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
        
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                                                  completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                               NSError *_Nullable error) {
                                                                      
                                                                      if (!configuration) {
                                                                          NSLog(@"Error retrieving discovery document: %@",
                                                                                [error localizedDescription]);
                                                                          result(nil);
                                                                          return;
                                                                      }
                                                                      
                                                                      [self performRefresh:configuration requestParameters:requestParameters result:result];
                                                                  }];
    } else {
        NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
        [OIDAuthorizationService discoverServiceConfigurationForIssuer:issuerUrl
                                                            completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                         NSError *_Nullable error) {
                                                                
                                                                if (!configuration) {
                                                                    NSLog(@"Error retrieving discovery document: %@",
                                                                          [error localizedDescription]);
                                                                    result(nil);
                                                                    return;
                                                                }
                                                                
                                                                [self performRefresh:configuration requestParameters:requestParameters result:result];
                                                            }];
    }
    
}

- (void)performRefresh:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(RequestParameters *)requestParameters result:(FlutterResult)result {
    OIDTokenRequest *tokenRequest =
    [[OIDTokenRequest alloc] initWithConfiguration:serviceConfiguration
                                         grantType:@"refresh_token"
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
        [processedResponses setValue:[[NSNumber alloc] initWithDouble:[tokenResponse.accessTokenExpirationDate timeIntervalSince1970]] forKey:@"accessTokenExpirationDate"];
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

- (RequestParameters *)processCallArguments:(NSDictionary*)arguments {
    RequestParameters *requestParameters = [[RequestParameters alloc] init];
    requestParameters.clientId = arguments[@"clientId"];
    requestParameters.clientSecret = arguments[@"clientSecret"];
    requestParameters.issuer = arguments[@"issuer"];
    requestParameters.discoveryUrl = arguments[@"discoveryUrl"];
    requestParameters.redirectUrl = arguments[@"redirectUrl"];
    requestParameters.loginHint = arguments[@"loginHint"];
    requestParameters.refreshToken = arguments[@"refreshToken"];
    requestParameters.scopes = [arguments objectForKey:@"scopes"] != [NSNull null] ? (NSArray *) arguments[@"scopes"] : nil;
    requestParameters.serviceConfigurationParameters = [arguments objectForKey:@"serviceConfiguration"] != [NSNull null] ? (NSDictionary *) arguments[@"serviceConfiguration"] : nil;
    requestParameters.additionalParameters = [arguments objectForKey:@"additionalParameters"] != [NSNull null] ? (NSDictionary *)arguments[@"additionalParameters"] : nil;
    return requestParameters;
}

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
    if ([currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url]) {
        currentAuthorizationFlow = nil;
        return YES;
    }
    
    return NO;
}
@end
