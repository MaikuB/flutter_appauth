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

+ (void)finishWithError:(NSString *)errorCode message:(NSString *)message  result:(FlutterResult)result {
    result([FlutterError errorWithCode:errorCode message:message details:nil]);
}

+ (NSString *) formatMessageWithError:(NSString *)messageFormat error:(NSError * _Nullable)error {
    NSString *formattedMessage = [NSString stringWithFormat:messageFormat, [error localizedDescription]];
    return formattedMessage;
}

@end

@implementation AppAuthAuthorization

- (id<OIDExternalUserAgentSession>)performAuthorization:(OIDServiceConfiguration *)serviceConfiguration clientId:(NSString*)clientId clientSecret:(NSString*)clientSecret scopes:(NSArray *)scopes redirectUrl:(NSString*)redirectUrl additionalParameters:(NSDictionary *)additionalParameters preferEphemeralSession:(BOOL)preferEphemeralSession result:(FlutterResult)result exchangeCode:(BOOL)exchangeCode nonce:(NSString*)nonce {
    return nil;
}

- (id<OIDExternalUserAgentSession>)performEndSessionRequest:(OIDServiceConfiguration *)serviceConfiguration requestParameters:(EndSessionRequestParameters *)requestParameters result:(FlutterResult)result {
    return nil;
}

@end
