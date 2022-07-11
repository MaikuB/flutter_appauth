#import <TargetConditionals.h>

#import "FlutterAppauthPlugin.h"

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
@property(nonatomic, strong) NSString *codeVerifier;
@property(nonatomic, strong) NSString *nonce;
@property(nonatomic, strong) NSString *authorizationCode;
@property(nonatomic, strong) NSArray *scopes;
@property(nonatomic, strong) NSDictionary *serviceConfigurationParameters;
@property(nonatomic, strong) NSDictionary *additionalParameters;
@property(nonatomic, readwrite) BOOL preferEphemeralSession;

@end

@implementation TokenRequestParameters
- (void)processArguments:(NSDictionary *)arguments {
    _clientId = [ArgumentProcessor processArgumentValue:arguments withKey:@"clientId"];
    _clientSecret = [ArgumentProcessor processArgumentValue:arguments withKey:@"clientSecret"];
    _issuer = [ArgumentProcessor processArgumentValue:arguments withKey:@"issuer"];
    _discoveryUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"discoveryUrl"];
    _redirectUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"redirectUrl"];
    _refreshToken = [ArgumentProcessor processArgumentValue:arguments withKey:@"refreshToken"];
    _nonce = [ArgumentProcessor processArgumentValue:arguments withKey:@"nonce"];
    _authorizationCode = [ArgumentProcessor processArgumentValue:arguments withKey:@"authorizationCode"];
    _codeVerifier = [ArgumentProcessor processArgumentValue:arguments withKey:@"codeVerifier"];
    _grantType = [ArgumentProcessor processArgumentValue:arguments withKey:@"grantType"];
    _scopes = [ArgumentProcessor processArgumentValue:arguments withKey:@"scopes"];
    _serviceConfigurationParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"serviceConfiguration"];
    _additionalParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"additionalParameters"];
    _preferEphemeralSession = [[ArgumentProcessor processArgumentValue:arguments withKey:@"preferEphemeralSession"] isEqual:@YES];
}

- (id)initWithArguments:(NSDictionary *)arguments {
    [self processArguments:arguments];
    return self;
}

@end

@interface AuthorizationTokenRequestParameters : TokenRequestParameters
@property(nonatomic, strong) NSString *loginHint;
@property(nonatomic, strong) NSArray *promptValues;
@property(nonatomic, strong) NSString *responseMode;
@end

@implementation AuthorizationTokenRequestParameters
- (id)initWithArguments:(NSDictionary *)arguments {
    [super processArguments:arguments];
    _loginHint = [ArgumentProcessor processArgumentValue:arguments withKey:@"loginHint"];
    _promptValues = [ArgumentProcessor processArgumentValue:arguments withKey:@"promptValues"];
    _responseMode = [ArgumentProcessor processArgumentValue:arguments withKey:@"responseMode"];
    return self;
}
@end

@implementation EndSessionRequestParameters
- (id)initWithArguments:(NSDictionary *)arguments {
    _idTokenHint= [ArgumentProcessor processArgumentValue:arguments withKey:@"idTokenHint"];
    _postLogoutRedirectUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"postLogoutRedirectUrl"];
    _state = [ArgumentProcessor processArgumentValue:arguments withKey:@"state"];
    _issuer = [ArgumentProcessor processArgumentValue:arguments withKey:@"issuer"];
    _discoveryUrl = [ArgumentProcessor processArgumentValue:arguments withKey:@"discoveryUrl"];
    _serviceConfigurationParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"serviceConfiguration"];
    _additionalParameters = [ArgumentProcessor processArgumentValue:arguments withKey:@"additionalParameters"];
    return self;
}
@end

@implementation FlutterAppauthPlugin

FlutterMethodChannel* channel;
AppAuthAuthorization* authorization;

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    channel = [FlutterMethodChannel
               methodChannelWithName:@"crossingthestreams.io/flutter_appauth"
               binaryMessenger:[registrar messenger]];
    FlutterAppauthPlugin* instance = [[FlutterAppauthPlugin alloc] init];
    [registrar addMethodCallDelegate:instance channel:channel];
    
#if TARGET_OS_OSX
    authorization = [[AppAuthMacOSAuthorization alloc] init];
    
    NSAppleEventManager *appleEventManager = [NSAppleEventManager sharedAppleEventManager];
    [appleEventManager setEventHandler:instance
                           andSelector:@selector(handleGetURLEvent:withReplyEvent:)
                         forEventClass:kInternetEventClass
                            andEventID:kAEGetURL];
#else
    authorization = [[AppAuthIOSAuthorization alloc] init];
    
    [registrar addApplicationDelegate:instance];
#endif
}

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    if ([AUTHORIZE_AND_EXCHANGE_CODE_METHOD isEqualToString:call.method]) {
        [self handleAuthorizeMethodCall:[call arguments] result:result exchangeCode:true];
    } else if([AUTHORIZE_METHOD isEqualToString:call.method]) {
        [self handleAuthorizeMethodCall:[call arguments] result:result exchangeCode:false];
    } else if([TOKEN_METHOD isEqualToString:call.method]) {
        [self handleTokenMethodCall:[call arguments] result:result];
    } else if([END_SESSION_METHOD isEqualToString:call.method]) {
        [self handleEndSessionMethodCall:[call arguments] result:result];
    } else {
        result(FlutterMethodNotImplemented);
    }
}

- (void)ensureAdditionalParametersInitialized:(AuthorizationTokenRequestParameters *)requestParameters {
    if(!requestParameters.additionalParameters) {
        requestParameters.additionalParameters = [[NSMutableDictionary alloc] init];
    }
}

-(void)handleAuthorizeMethodCall:(NSDictionary*)arguments result:(FlutterResult)result exchangeCode:(BOOL)exchangeCode {
    AuthorizationTokenRequestParameters *requestParameters = [[AuthorizationTokenRequestParameters alloc] initWithArguments:arguments];
    [self ensureAdditionalParametersInitialized:requestParameters];
    if(requestParameters.loginHint) {
        [requestParameters.additionalParameters setValue:requestParameters.loginHint forKey:@"login_hint"];
    }
    if(requestParameters.promptValues) {
        [requestParameters.additionalParameters setValue:[requestParameters.promptValues componentsJoinedByString:@" "] forKey:@"prompt"];
    }
    if(requestParameters.responseMode) {
        [requestParameters.additionalParameters setValue:requestParameters.responseMode forKey:@"response_mode"];
    }

    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration = [self processServiceConfigurationParameters:requestParameters.serviceConfigurationParameters];
        _currentAuthorizationFlow = [authorization performAuthorization:serviceConfiguration clientId:requestParameters.clientId clientSecret:requestParameters.clientSecret scopes:requestParameters.scopes redirectUrl:requestParameters.redirectUrl additionalParameters:requestParameters.additionalParameters preferEphemeralSession:requestParameters.preferEphemeralSession result:result exchangeCode:exchangeCode nonce:requestParameters.nonce];
    } else if (requestParameters.discoveryUrl) {
        NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                                                  completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                               NSError *_Nullable error) {

            if (!configuration) {
                [self finishWithDiscoveryError:error result:result];
                return;
            }

            self->_currentAuthorizationFlow = [authorization performAuthorization:configuration clientId:requestParameters.clientId clientSecret:requestParameters.clientSecret scopes:requestParameters.scopes redirectUrl:requestParameters.redirectUrl additionalParameters:requestParameters.additionalParameters preferEphemeralSession:requestParameters.preferEphemeralSession result:result exchangeCode:exchangeCode nonce:requestParameters.nonce];
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

            self->_currentAuthorizationFlow = [authorization performAuthorization:configuration clientId:requestParameters.clientId clientSecret:requestParameters.clientSecret scopes:requestParameters.scopes redirectUrl:requestParameters.redirectUrl additionalParameters:requestParameters.additionalParameters preferEphemeralSession:requestParameters.preferEphemeralSession result:result exchangeCode:exchangeCode nonce:requestParameters.nonce];
        }];
    }
}

- (void)finishWithDiscoveryError:(NSError * _Nullable)error result:(FlutterResult)result {
    NSString *message = [NSString stringWithFormat:DISCOVERY_ERROR_MESSAGE_FORMAT, [error localizedDescription]];
    [FlutterAppAuth finishWithError:DISCOVERY_ERROR_CODE message:message result:result];
}


- (OIDServiceConfiguration *)processServiceConfigurationParameters:(NSDictionary*)serviceConfigurationParameters {
    NSURL *endSessionEndpoint = serviceConfigurationParameters[@"endSessionEndpoint"] == [NSNull null] ? nil : [NSURL URLWithString:serviceConfigurationParameters[@"endSessionEndpoint"]];
    OIDServiceConfiguration *serviceConfiguration =
    [[OIDServiceConfiguration alloc]
     initWithAuthorizationEndpoint:[NSURL URLWithString:serviceConfigurationParameters[@"authorizationEndpoint"]]
     tokenEndpoint:[NSURL URLWithString:serviceConfigurationParameters[@"tokenEndpoint"]] issuer:nil registrationEndpoint:nil endSessionEndpoint:endSessionEndpoint];
    return serviceConfiguration;
}

-(void)handleTokenMethodCall:(NSDictionary*)arguments result:(FlutterResult)result {
    TokenRequestParameters *requestParameters = [[TokenRequestParameters alloc] initWithArguments:arguments];
    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration = [self processServiceConfigurationParameters:requestParameters.serviceConfigurationParameters];
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

-(void)handleEndSessionMethodCall:(NSDictionary*)arguments result:(FlutterResult)result {
    EndSessionRequestParameters *requestParameters = [[EndSessionRequestParameters alloc] initWithArguments:arguments];
    if(requestParameters.serviceConfigurationParameters != nil) {
        OIDServiceConfiguration *serviceConfiguration = [self processServiceConfigurationParameters:requestParameters.serviceConfigurationParameters];
        _currentAuthorizationFlow = [authorization performEndSessionRequest:serviceConfiguration requestParameters:requestParameters result:result];
    } else if (requestParameters.discoveryUrl) {
        NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
        
        [OIDAuthorizationService discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                                                  completion:^(OIDServiceConfiguration *_Nullable configuration,
                                                                               NSError *_Nullable error) {
            if (!configuration) {
                [self finishWithDiscoveryError:error result:result];
                return;
            }
            
            self->_currentAuthorizationFlow = [authorization performEndSessionRequest:configuration requestParameters:requestParameters result:result];
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
            
            self->_currentAuthorizationFlow = [authorization performEndSessionRequest:configuration requestParameters:requestParameters result:result];
        }];
    }
}

- (void)performTokenRequest:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(TokenRequestParameters *)requestParameters result:(FlutterResult)result {
    OIDTokenRequest *tokenRequest =
    [[OIDTokenRequest alloc] initWithConfiguration:serviceConfiguration
                                         grantType:requestParameters.grantType
                                 authorizationCode:requestParameters.authorizationCode
                                       redirectURL:[NSURL URLWithString:requestParameters.redirectUrl]
                                          clientID:requestParameters.clientId
                                      clientSecret:requestParameters.clientSecret
                                            scopes:requestParameters.scopes
                                      refreshToken:requestParameters.refreshToken
                                      codeVerifier:requestParameters.codeVerifier
                              additionalParameters:requestParameters.additionalParameters];
    [OIDAuthorizationService performTokenRequest:tokenRequest
                                        callback:^(OIDTokenResponse *_Nullable response,
                                                   NSError *_Nullable error) {
        if (response) {
            result([FlutterAppAuth processResponses:response authResponse:nil]);                                           } else {
                NSString *message = [NSString stringWithFormat:TOKEN_ERROR_MESSAGE_FORMAT, [error localizedDescription]];
                [FlutterAppAuth finishWithError:TOKEN_ERROR_CODE message:message result:result];
            }
    }];
}

#if TARGET_OS_IOS
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
#endif

#if TARGET_OS_OSX
- (void)handleGetURLEvent:(NSAppleEventDescriptor *)event
           withReplyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    NSURL *URL = [NSURL URLWithString:URLString];
    [_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:URL];
    _currentAuthorizationFlow = nil;
}
#endif

@end
