#import <TargetConditionals.h>

#import "FlutterAppauthPlugin_Private.h"

#pragma mark - InsecureURLProtocol

@interface InsecureURLProtocol : NSURLProtocol <NSURLSessionDataDelegate>
@property (nonatomic, strong) NSURLSessionDataTask *dataTask;
@property (nonatomic, strong) NSURLSession *session;
@end

static NSString *const kInsecureURLProtocolHandledKey = @"InsecureURLProtocolHandled";

// Hosts of the OIDC providers with a live insecure registration. While the
// protocol is registered it is consulted by every NSURLSession in the
// process and may only intercept these host:port pairs; everything else
// keeps its certificate verification. The set is guarded because
// canInitWithRequest runs on URL-loading threads while arming happens on the
// platform thread. Hosts stay armed after their exchange ends —
// unregisterClass: cannot know which registration to drop, and overlapping
// exchanges share it; a host only gets here because its deployment opted
// into the insecure flag.
static NSMutableSet<NSString *> *_insecureAllowedHosts = nil;

// The interception key of a URL: host (case-folded) and port, with the
// scheme default filled in (https 443, http 80) so a provider on :443 and
// one on :8443 stay distinct.
static NSString *InsecureHostKey(NSURL *url) {
  NSNumber *port = url.port;
  if (port == nil) {
    port = [url.scheme.lowercaseString isEqualToString:@"http"] ? @80 : @443;
  }
  return [NSString stringWithFormat:@"%@:%@", url.host.lowercaseString, port];
}

// A usable string from a channel value: Dart null arrives over the method
// channel as NSNull, which is non-nil and would poison a ?: chain or an
// @[] literal (the same normalization processServiceConfigurationParameters:
// applies).
static NSString *AsNSString(id value) {
  return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSString *EndpointString(NSDictionary *configuration, NSString *key) {
  return AsNSString(configuration[key]);
}

@implementation InsecureURLProtocol

+ (NSMutableSet<NSString *> *)allowedHosts {
  static dispatch_once_t once;
  dispatch_once(&once, ^{
    _insecureAllowedHosts = [NSMutableSet set];
  });
  return _insecureAllowedHosts;
}

+ (void)armForIssuer:(NSString *)issuer
         discoveryUrl:(NSString *)discoveryUrl
serviceConfigurationParameters:(NSDictionary *)serviceConfigurationParameters {
  // Arm every host the exchange can contact: the configuration's endpoints
  // (what the app usually passes, and what the exchange will actually hit),
  // plus the issuer or discovery URL for the discovery flow. A host the
  // exchange needs but that is not armed fails its certificate check.
  // AsNSString and EndpointString filter the NSNulls the channel sends for
  // absent fields — the same normalization
  // processServiceConfigurationParameters: needs on its end-session field;
  // the candidates are collected into a mutable array because an @[]
  // literal throws on a nil element.
  NSMutableArray<NSString *> *endpoints = [NSMutableArray array];
  for (NSString *key in @[
    @"authorizationEndpoint",
    @"tokenEndpoint",
    @"endSessionEndpoint",
  ]) {
    NSString *endpoint = EndpointString(serviceConfigurationParameters, key);
    if (endpoint) {
      [endpoints addObject:endpoint];
    }
  }
  issuer = AsNSString(issuer);
  if (issuer) {
    [endpoints addObject:issuer];
  }
  discoveryUrl = AsNSString(discoveryUrl);
  if (discoveryUrl) {
    [endpoints addObject:discoveryUrl];
  }

  // Keys are computed before the critical section: the same lock guards
  // every URL load in the process while the protocol is registered.
  NSMutableSet<NSString *> *allowedHosts = [InsecureURLProtocol allowedHosts];
  NSMutableArray<NSString *> *keys = [NSMutableArray array];
  for (NSString *endpoint in endpoints) {
    NSURL *providerUrl = [NSURL URLWithString:endpoint];
    if (!providerUrl.host) {
      continue;
    }
    [keys addObject:InsecureHostKey(providerUrl)];
  }
  @synchronized(allowedHosts) {
    [allowedHosts addObjectsFromArray:keys];
  }
}

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  if ([self propertyForKey:kInsecureURLProtocolHandledKey inRequest:request] != nil) {
    return NO;
  }
  // Only the OIDC provider's host (and port) may be intercepted: everything
  // else keeps its certificate verification even during an insecure
  // exchange.
  if (!request.URL.host) {
    return NO;
  }
  NSMutableSet<NSString *> *allowedHosts = [InsecureURLProtocol allowedHosts];
  @synchronized(allowedHosts) {
    return [allowedHosts containsObject:InsecureHostKey(request.URL)];
  }
}

+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

- (void)startLoading {
  NSMutableURLRequest *mutableRequest = [self.request mutableCopy];
  [InsecureURLProtocol setProperty:@YES
                            forKey:kInsecureURLProtocolHandledKey
                         inRequest:mutableRequest];

  NSURLSessionConfiguration *config =
      [NSURLSessionConfiguration defaultSessionConfiguration];
  config.protocolClasses = @[];

  self.session = [NSURLSession sessionWithConfiguration:config
                                               delegate:self
                                          delegateQueue:[NSOperationQueue mainQueue]];
  self.dataTask = [self.session dataTaskWithRequest:mutableRequest];
  [self.dataTask resume];
}

- (void)stopLoading {
  [self.dataTask cancel];
}

- (void)URLSession:(NSURLSession *)session
    didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
      completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition,
                                  NSURLCredential *_Nullable credential))completionHandler {
  if (challenge.protectionSpace.authenticationMethod ==
      NSURLAuthenticationMethodServerTrust) {
    SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
    completionHandler(NSURLSessionAuthChallengeUseCredential,
                      [NSURLCredential credentialForTrust:serverTrust]);
  } else {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
didReceiveResponse:(NSURLResponse *)response
 completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
  [self.client URLProtocol:self
        didReceiveResponse:response
        cacheStoragePolicy:NSURLCacheStorageNotAllowed];
  completionHandler(NSURLSessionResponseAllow);
}

- (void)URLSession:(NSURLSession *)session
          dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data {
  [self.client URLProtocol:self didLoadData:data];
}

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
  if (error) {
    [self.client URLProtocol:self didFailWithError:error];
  } else {
    [self.client URLProtocolDidFinishLoading:self];
  }
}

@end

#pragma mark - ArgumentProcessor

@interface ArgumentProcessor : NSObject
+ (id _Nullable)processArgumentValue:(NSDictionary *)arguments
                             withKey:(NSString *)key;
@end

@implementation ArgumentProcessor

+ (id _Nullable)processArgumentValue:(NSDictionary *)arguments
                             withKey:(NSString *)key {
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
@property(nonatomic, strong) NSNumber *externalUserAgent;
@property(nonatomic, assign) BOOL allowInsecureConnections;

@end

@implementation TokenRequestParameters
- (void)processArguments:(NSDictionary *)arguments {
  _clientId = [ArgumentProcessor processArgumentValue:arguments
                                              withKey:@"clientId"];
  _clientSecret = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"clientSecret"];
  _issuer = [ArgumentProcessor processArgumentValue:arguments
                                            withKey:@"issuer"];
  _discoveryUrl = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"discoveryUrl"];
  _redirectUrl = [ArgumentProcessor processArgumentValue:arguments
                                                 withKey:@"redirectUrl"];
  _refreshToken = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"refreshToken"];
  _nonce = [ArgumentProcessor processArgumentValue:arguments withKey:@"nonce"];
  _authorizationCode =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"authorizationCode"];
  _codeVerifier = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"codeVerifier"];
  _grantType = [ArgumentProcessor processArgumentValue:arguments
                                               withKey:@"grantType"];
  _scopes = [ArgumentProcessor processArgumentValue:arguments
                                            withKey:@"scopes"];
  _serviceConfigurationParameters =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"serviceConfiguration"];
  _additionalParameters =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"additionalParameters"];
  _externalUserAgent =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"externalUserAgent"];
  NSNumber *allowInsecure =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"allowInsecureConnections"];
  _allowInsecureConnections = allowInsecure ? [allowInsecure boolValue] : NO;
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
  _loginHint = [ArgumentProcessor processArgumentValue:arguments
                                               withKey:@"loginHint"];
  _promptValues = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"promptValues"];
  _responseMode = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"responseMode"];
  return self;
}
@end

@implementation EndSessionRequestParameters
- (id)initWithArguments:(NSDictionary *)arguments {
  _idTokenHint = [ArgumentProcessor processArgumentValue:arguments
                                                 withKey:@"idTokenHint"];
  _postLogoutRedirectUrl =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"postLogoutRedirectUrl"];
  _state = [ArgumentProcessor processArgumentValue:arguments withKey:@"state"];
  _issuer = [ArgumentProcessor processArgumentValue:arguments
                                            withKey:@"issuer"];
  _discoveryUrl = [ArgumentProcessor processArgumentValue:arguments
                                                  withKey:@"discoveryUrl"];
  _serviceConfigurationParameters =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"serviceConfiguration"];
  _additionalParameters =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"additionalParameters"];
  _externalUserAgent =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"externalUserAgent"];
  NSNumber *allowInsecure =
      [ArgumentProcessor processArgumentValue:arguments
                                      withKey:@"allowInsecureConnections"];
  _allowInsecureConnections = allowInsecure ? [allowInsecure boolValue] : NO;
  return self;
}
@end

static AppAuthAuthorization *authorization;

@implementation FlutterAppauthPlugin

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar> *)registrar {
  FlutterMethodChannel *channel = [FlutterMethodChannel
      methodChannelWithName:@"crossingthestreams.io/flutter_appauth"
            binaryMessenger:[registrar messenger]];
  FlutterAppauthPlugin *instance = [[FlutterAppauthPlugin alloc] init];
  [registrar addMethodCallDelegate:instance channel:channel];

#if TARGET_OS_OSX
  authorization = [[AppAuthMacOSAuthorization alloc] init];

  NSAppleEventManager *appleEventManager =
      [NSAppleEventManager sharedAppleEventManager];
  [appleEventManager
      setEventHandler:instance
          andSelector:@selector(handleGetURLEvent:withReplyEvent:)
        forEventClass:kInternetEventClass
           andEventID:kAEGetURL];
#else
  authorization = [[AppAuthIOSAuthorization alloc] init];

  [registrar addApplicationDelegate:instance];
#endif
}

- (void)handleMethodCall:(FlutterMethodCall *)call
                  result:(FlutterResult)result {
  if ([AUTHORIZE_AND_EXCHANGE_CODE_METHOD isEqualToString:call.method]) {
    [self handleAuthorizeMethodCall:[call arguments]
                             result:result
                       exchangeCode:true];
  } else if ([AUTHORIZE_METHOD isEqualToString:call.method]) {
    [self handleAuthorizeMethodCall:[call arguments]
                             result:result
                       exchangeCode:false];
  } else if ([TOKEN_METHOD isEqualToString:call.method]) {
    [self handleTokenMethodCall:[call arguments] result:result];
  } else if ([END_SESSION_METHOD isEqualToString:call.method]) {
    [self handleEndSessionMethodCall:[call arguments] result:result];
  } else {
    result(FlutterMethodNotImplemented);
  }
}

- (void)ensureAdditionalParametersInitialized:
    (AuthorizationTokenRequestParameters *)requestParameters {
  if (!requestParameters.additionalParameters) {
    requestParameters.additionalParameters = [[NSMutableDictionary alloc] init];
  }
}

- (void)handleAuthorizeMethodCall:(NSDictionary *)arguments
                           result:(FlutterResult)result
                     exchangeCode:(BOOL)exchangeCode {
  AuthorizationTokenRequestParameters *requestParameters =
      [[AuthorizationTokenRequestParameters alloc] initWithArguments:arguments];
  [self ensureAdditionalParametersInitialized:requestParameters];
  if (requestParameters.loginHint) {
    [requestParameters.additionalParameters setValue:requestParameters.loginHint
                                              forKey:@"login_hint"];
  }
  if (requestParameters.promptValues) {
    [requestParameters.additionalParameters
        setValue:[requestParameters.promptValues componentsJoinedByString:@" "]
          forKey:@"prompt"];
  }
  if (requestParameters.responseMode) {
    [requestParameters.additionalParameters
        setValue:requestParameters.responseMode
          forKey:@"response_mode"];
  }

  if (requestParameters.allowInsecureConnections) {
    [InsecureURLProtocol armForIssuer:requestParameters.issuer
                          discoveryUrl:requestParameters.discoveryUrl
       serviceConfigurationParameters:requestParameters.serviceConfigurationParameters];
    [NSURLProtocol registerClass:[InsecureURLProtocol class]];
  }

  FlutterResult insecureResult = ^(id _Nullable value) {
    if (requestParameters.allowInsecureConnections) {
      [NSURLProtocol unregisterClass:[InsecureURLProtocol class]];
    }
    result(value);
  };

  if (requestParameters.serviceConfigurationParameters != nil) {
    OIDServiceConfiguration *serviceConfiguration =
        [self processServiceConfigurationParameters:
                  requestParameters.serviceConfigurationParameters];
    _currentAuthorizationFlow = [authorization
        performAuthorization:serviceConfiguration
                    clientId:requestParameters.clientId
                clientSecret:requestParameters.clientSecret
                      scopes:requestParameters.scopes
                 redirectUrl:requestParameters.redirectUrl
        additionalParameters:requestParameters.additionalParameters
           externalUserAgent:requestParameters.externalUserAgent
                      result:insecureResult
                exchangeCode:exchangeCode
                       nonce:requestParameters.nonce];
  } else if (requestParameters.discoveryUrl) {
    NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];
    [OIDAuthorizationService
        discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                         completion:^(
                                             OIDServiceConfiguration
                                                 *_Nullable configuration,
                                             NSError *_Nullable error) {
                                           if (!configuration) {
                                             [self
                                                 finishWithDiscoveryError:error
                                                                   result:
                                                                       insecureResult];
                                             return;
                                           }

                                           self->_currentAuthorizationFlow = [authorization
                                               performAuthorization:
                                                   configuration
                                                           clientId:
                                                               requestParameters
                                                                   .clientId
                                                       clientSecret:
                                                           requestParameters
                                                               .clientSecret
                                                             scopes:
                                                                 requestParameters
                                                                     .scopes
                                                        redirectUrl:
                                                            requestParameters
                                                                .redirectUrl
                                               additionalParameters:
                                                   requestParameters
                                                       .additionalParameters
                                                  externalUserAgent:
                                                      requestParameters
                                                          .externalUserAgent
                                                             result:insecureResult
                                                       exchangeCode:exchangeCode
                                                              nonce:
                                                                  requestParameters
                                                                      .nonce];
                                         }];
  } else {
    NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
    [OIDAuthorizationService
        discoverServiceConfigurationForIssuer:issuerUrl
                                   completion:^(OIDServiceConfiguration
                                                    *_Nullable configuration,
                                                NSError *_Nullable error) {
                                     if (!configuration) {
                                       [self finishWithDiscoveryError:error
                                                               result:insecureResult];
                                       return;
                                     }

                                     self->_currentAuthorizationFlow =
                                         [authorization
                                             performAuthorization:configuration
                                                         clientId:
                                                             requestParameters
                                                                 .clientId
                                                     clientSecret:
                                                         requestParameters
                                                             .clientSecret
                                                           scopes:
                                                               requestParameters
                                                                   .scopes
                                                      redirectUrl:
                                                          requestParameters
                                                              .redirectUrl
                                             additionalParameters:
                                                 requestParameters
                                                     .additionalParameters
                                                externalUserAgent:
                                                    requestParameters
                                                        .externalUserAgent
                                                           result:insecureResult
                                                     exchangeCode:exchangeCode
                                                            nonce:
                                                                requestParameters
                                                                    .nonce];
                                   }];
  }
}

- (void)finishWithDiscoveryError:(NSError *_Nullable)error
                          result:(FlutterResult)result {
  NSString *message = [NSString stringWithFormat:DISCOVERY_ERROR_MESSAGE_FORMAT,
                                                 [error localizedDescription]];
  [FlutterAppAuth finishWithError:DISCOVERY_ERROR_CODE
                          message:message
                           result:result
                            error:error];
}

- (OIDServiceConfiguration *)processServiceConfigurationParameters:
    (NSDictionary *)serviceConfigurationParameters {
  NSURL *endSessionEndpoint = [NSURL
      URLWithString:EndpointString(serviceConfigurationParameters,
                                   @"endSessionEndpoint")];
  OIDServiceConfiguration *serviceConfiguration =
      [[OIDServiceConfiguration alloc]
          initWithAuthorizationEndpoint:
              [NSURL URLWithString:EndpointString(
                                       serviceConfigurationParameters,
                                       @"authorizationEndpoint")]
                          tokenEndpoint:
                              [NSURL
                                  URLWithString:EndpointString(
                                                    serviceConfigurationParameters,
                                                    @"tokenEndpoint")]
                                 issuer:nil
                   registrationEndpoint:nil
                     endSessionEndpoint:endSessionEndpoint];
  return serviceConfiguration;
}

- (void)handleTokenMethodCall:(NSDictionary *)arguments
                       result:(FlutterResult)result {
  TokenRequestParameters *requestParameters =
      [[TokenRequestParameters alloc] initWithArguments:arguments];

  if (requestParameters.allowInsecureConnections) {
    [InsecureURLProtocol armForIssuer:requestParameters.issuer
                          discoveryUrl:requestParameters.discoveryUrl
       serviceConfigurationParameters:requestParameters.serviceConfigurationParameters];
    [NSURLProtocol registerClass:[InsecureURLProtocol class]];
  }

  FlutterResult insecureResult = ^(id _Nullable value) {
    if (requestParameters.allowInsecureConnections) {
      [NSURLProtocol unregisterClass:[InsecureURLProtocol class]];
    }
    result(value);
  };

  if (requestParameters.serviceConfigurationParameters != nil) {
    OIDServiceConfiguration *serviceConfiguration =
        [self processServiceConfigurationParameters:
                  requestParameters.serviceConfigurationParameters];
    [self performTokenRequest:serviceConfiguration
            requestParameters:requestParameters
                       result:insecureResult];
  } else if (requestParameters.discoveryUrl) {
    NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];

    [OIDAuthorizationService
        discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                         completion:^(
                                             OIDServiceConfiguration
                                                 *_Nullable configuration,
                                             NSError *_Nullable error) {
                                           if (!configuration) {
                                             [self
                                                 finishWithDiscoveryError:error
                                                                   result:
                                                                       insecureResult];
                                             return;
                                           }

                                           [self
                                               performTokenRequest:configuration
                                                 requestParameters:
                                                     requestParameters
                                                            result:insecureResult];
                                         }];
  } else {
    NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
    [OIDAuthorizationService
        discoverServiceConfigurationForIssuer:issuerUrl
                                   completion:^(OIDServiceConfiguration
                                                    *_Nullable configuration,
                                                NSError *_Nullable error) {
                                     if (!configuration) {
                                       [self finishWithDiscoveryError:error
                                                               result:insecureResult];
                                       return;
                                     }

                                     [self performTokenRequest:configuration
                                             requestParameters:requestParameters
                                                        result:insecureResult];
                                   }];
  }
}

- (void)handleEndSessionMethodCall:(NSDictionary *)arguments
                            result:(FlutterResult)result {
  EndSessionRequestParameters *requestParameters =
      [[EndSessionRequestParameters alloc] initWithArguments:arguments];

  if (requestParameters.allowInsecureConnections) {
    [InsecureURLProtocol armForIssuer:requestParameters.issuer
                          discoveryUrl:requestParameters.discoveryUrl
       serviceConfigurationParameters:requestParameters.serviceConfigurationParameters];
    [NSURLProtocol registerClass:[InsecureURLProtocol class]];
  }

  FlutterResult insecureResult = ^(id _Nullable value) {
    if (requestParameters.allowInsecureConnections) {
      [NSURLProtocol unregisterClass:[InsecureURLProtocol class]];
    }
    result(value);
  };

  if (requestParameters.serviceConfigurationParameters != nil) {
    OIDServiceConfiguration *serviceConfiguration =
        [self processServiceConfigurationParameters:
                  requestParameters.serviceConfigurationParameters];
    _currentAuthorizationFlow =
        [authorization performEndSessionRequest:serviceConfiguration
                              requestParameters:requestParameters
                                         result:insecureResult];
  } else if (requestParameters.discoveryUrl) {
    NSURL *discoveryUrl = [NSURL URLWithString:requestParameters.discoveryUrl];

    [OIDAuthorizationService
        discoverServiceConfigurationForDiscoveryURL:discoveryUrl
                                         completion:^(
                                             OIDServiceConfiguration
                                                 *_Nullable configuration,
                                             NSError *_Nullable error) {
                                           if (!configuration) {
                                             [self
                                                 finishWithDiscoveryError:error
                                                                   result:
                                                                       insecureResult];
                                             return;
                                           }

                                           self->_currentAuthorizationFlow =
                                               [authorization
                                                   performEndSessionRequest:
                                                       configuration
                                                          requestParameters:
                                                              requestParameters
                                                                     result:
                                                                         insecureResult];
                                         }];
  } else {
    NSURL *issuerUrl = [NSURL URLWithString:requestParameters.issuer];
    [OIDAuthorizationService
        discoverServiceConfigurationForIssuer:issuerUrl
                                   completion:^(OIDServiceConfiguration
                                                    *_Nullable configuration,
                                                NSError *_Nullable error) {
                                     if (!configuration) {
                                       [self finishWithDiscoveryError:error
                                                               result:insecureResult];
                                       return;
                                     }

                                     self->_currentAuthorizationFlow =
                                         [authorization
                                             performEndSessionRequest:
                                                 configuration
                                                    requestParameters:
                                                        requestParameters
                                                               result:insecureResult];
                                   }];
  }
}

- (void)performTokenRequest:(OIDServiceConfiguration *)serviceConfiguration
          requestParameters:(TokenRequestParameters *)requestParameters
                     result:(FlutterResult)result {
  OIDTokenRequest *tokenRequest = [[OIDTokenRequest alloc]
      initWithConfiguration:serviceConfiguration
                  grantType:requestParameters.grantType
          authorizationCode:requestParameters.authorizationCode
                redirectURL:[NSURL URLWithString:requestParameters.redirectUrl]
                   clientID:requestParameters.clientId
               clientSecret:requestParameters.clientSecret
                     scopes:requestParameters.scopes
               refreshToken:requestParameters.refreshToken
               codeVerifier:requestParameters.codeVerifier
       additionalParameters:requestParameters.additionalParameters];
  [OIDAuthorizationService
      performTokenRequest:tokenRequest
                 callback:^(OIDTokenResponse *_Nullable response,
                            NSError *_Nullable error) {
                   if (response) {
                     result([FlutterAppAuth processResponses:response
                                                authResponse:nil]);
                   } else {
                     NSString *message = [NSString
                         stringWithFormat:TOKEN_ERROR_MESSAGE_FORMAT,
                                          [error localizedDescription]];
                     [FlutterAppAuth finishWithError:TOKEN_ERROR_CODE
                                             message:message
                                              result:result
                                               error:error];
                   }
                 }];
}

#if TARGET_OS_IOS
- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
            options:
                (NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options {
  if ([_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:url
                                                              error:nil]) {
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
  NSString *URLString =
      [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
  NSURL *URL = [NSURL URLWithString:URLString];
  [_currentAuthorizationFlow resumeExternalUserAgentFlowWithURL:URL error:nil];
  _currentAuthorizationFlow = nil;
}
#endif

@end
