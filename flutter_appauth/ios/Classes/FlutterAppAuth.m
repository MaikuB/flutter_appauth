#import "FlutterAppAuth.h"

@implementation FlutterAppAuth

+ (NSMutableDictionary *)processResponses:(OIDTokenResponse*) tokenResponse authResponse:(OIDAuthorizationResponse*) authResponse {
    NSMutableDictionary *processedResponses = [[NSMutableDictionary alloc] init];
    if(tokenResponse.accessToken) {
        [processedResponses setValue:tokenResponse.accessToken forKey:@"accessToken"];
    }
    if(tokenResponse.accessTokenExpirationDate) {
        [processedResponses setValue:[[NSNumber alloc] initWithDouble:[tokenResponse.accessTokenExpirationDate timeIntervalSince1970] * 1000] forKey:@"accessTokenExpirationTime"];
    }
    if(authResponse) {
        if (authResponse.additionalParameters) {
            [processedResponses setObject:authResponse.additionalParameters forKey:@"authorizationAdditionalParameters"];
        }
        if (authResponse.request && authResponse.request.nonce) {
            [processedResponses setObject:authResponse.request.nonce forKey:@"nonce"];
        }
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
    if (tokenResponse.scope) {
        [processedResponses setObject:[tokenResponse.scope componentsSeparatedByString: @" "] forKey:@"scopes"];
    }
    
    return processedResponses;
}

+ (void)finishWithError:(NSString *)errorCode message:(NSString *)message result:(FlutterResult)result error:(NSError * _Nullable)error {

    NSMutableDictionary<NSString *, id> *details = [NSMutableDictionary dictionary];

    if (error) {
        id authError = error.userInfo[OIDOAuthErrorResponseErrorKey];
        NSDictionary<NSString *, id> *authErrorMap = [authError isKindOfClass:[NSDictionary class]] ? authError : nil;
        
        if (authErrorMap) {
            if ([authErrorMap objectForKey:OIDOAuthErrorFieldError]) {
                [details setObject:authErrorMap[OIDOAuthErrorFieldError] forKey:OIDOAuthErrorFieldError];
            }
            if ([authErrorMap objectForKey:OIDOAuthErrorFieldErrorDescription]) {
                [details setObject:authErrorMap[OIDOAuthErrorFieldErrorDescription] forKey:OIDOAuthErrorFieldErrorDescription];
            }
            if ([authErrorMap objectForKey:OIDOAuthErrorFieldErrorURI]) {
                [details setObject:authErrorMap[OIDOAuthErrorFieldErrorURI] forKey:OIDOAuthErrorFieldErrorURI];
            }
        }
        if (error.domain) {
            [details setObject:error.domain forKey:@"type"];
        }
        if (error.code) {
            [details setObject:[@(error.code) stringValue] forKey:@"code"];
        }
        
        id underlyingErr = [error.userInfo objectForKey:NSUnderlyingErrorKey];
        NSError *underlyingError = [underlyingErr isKindOfClass:[NSError class]] ? underlyingErr : nil;
        if (underlyingError) {
            if (underlyingError.domain) {
                [details setObject:underlyingError.domain forKey:@"domain"];
            }

            if (underlyingError.debugDescription) {
                [details setObject:underlyingError.debugDescription forKey:@"root_cause_debug_description"];
            }
        }
        
        if (error.debugDescription) {
            [details setObject:error.debugDescription forKey:@"error_debug_description"];
        }
        
        bool userDidCancel = [error.domain  isEqual: @"org.openid.appauth.general"] 
                             && error.code == OIDErrorCodeUserCanceledAuthorizationFlow;
        [details setObject:(userDidCancel ? @"true" : @"false") forKey:@"user_did_cancel"];

    }
    result([FlutterError errorWithCode:errorCode message:message details:details]);
}

+ (NSString *) formatMessageWithError:(NSString *)messageFormat error:(NSError * _Nullable)error {
    NSString *formattedMessage = [NSString stringWithFormat:messageFormat, [error localizedDescription]];
    return formattedMessage;
}

@end

@implementation AppAuthAuthorization

- (id<OIDExternalUserAgentSession>)performAuthorization:(OIDServiceConfiguration *)serviceConfiguration clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret scopes:(NSArray *)scopes redirectUrl:(NSString*)redirectUrl additionalParameters:(NSDictionary *)additionalParameters externalUserAgent:(NSString*)externalUserAgent result:(FlutterResult)result exchangeCode:(BOOL)exchangeCode nonce:(NSString*)nonce {
    return nil;
}

- (id<OIDExternalUserAgentSession>)performEndSessionRequest:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(EndSessionRequestParameters *)requestParameters result:(FlutterResult)result {
    return nil;
}

@end
