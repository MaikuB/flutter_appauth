#if os(macOS)
import FlutterMacOS
#else
import Flutter
#endif

import AppAuth
import Foundation

class FlutterAppAuth: NSObject {
    static func processResponses(_ tokenResponse: OIDTokenResponse, authResponse: OIDAuthorizationResponse?) -> [String: Any] {
        var result = [String: Any]()
        if let tokenResponse = tokenResponse {
            result["accessToken"] = tokenResponse.accessToken
            result["idToken"] = tokenResponse.idToken
            result["refreshToken"] = tokenResponse.refreshToken
            result["tokenType"] = tokenResponse.tokenType
            result["expiresIn"] = tokenResponse.expiresIn
        }
        if let authResponse = authResponse {
            result["authorizationCode"] = authResponse.authorizationCode
            result["state"] = authResponse.state
        }
        return result
    }

    static func finishWithError(_ errorCode: String, message: String, result: FlutterResult) {
        result(FlutterError(code: errorCode, message: message, details: nil))
    }

    static func formatMessage(with error: Error?) -> String {
        if let error = error {
            return String(format: error.localizedDescription)
        } else {
            return ""
        }
    }
}

let AUTHORIZE_METHOD = "authorize"
let AUTHORIZE_AND_EXCHANGE_CODE_METHOD = "authorizeAndExchangeCode"
let TOKEN_METHOD = "token"
let END_SESSION_METHOD = "endSession"
let AUTHORIZE_ERROR_CODE = "authorize_failed"
let AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE = "authorize_and_exchange_code_failed"
let DISCOVERY_ERROR_CODE = "discovery_failed"
let TOKEN_ERROR_CODE = "token_failed"
let END_SESSION_ERROR_CODE = "end_session_failed"
let DISCOVERY_ERROR_MESSAGE_FORMAT = "Error retrieving discovery document: %@"
let TOKEN_ERROR_MESSAGE_FORMAT = "Failed to get token: %@"
let AUTHORIZE_ERROR_MESSAGE_FORMAT = "Failed to authorize: %@"
let END_SESSION_ERROR_MESSAGE_FORMAT = "Failed to end session: %@"

struct EndSessionRequestParameters {
    var idTokenHint: String?
    var postLogoutRedirectUrl: String?
    var state: String?
    var issuer: String?
    var discoveryUrl: String?
    var serviceConfigurationParameters: [String: Any]?
    var additionalParameters: [String: Any]?
    var preferEphemeralSession: Bool
}

class AppAuthAuthorization: NSObject {
    func performAuthorization(_ serviceConfiguration: OIDServiceConfiguration, clientId: String, clientSecret: String, scopes: [String], redirectUrl: String, additionalParameters: [String: Any], preferEphemeralSession: Bool, result: FlutterResult, exchangeCode: Bool, nonce: String?) -> OIDExternalUserAgentSession? {
        let request = OIDAuthorizationRequest(
            configuration: serviceConfiguration,
            clientId: clientId,
            clientSecret: clientSecret,
            scopes: scopes,
            redirectURL: URL(string: redirectUrl)!,
            responseType: exchangeCode ? OIDResponseTypeCode : OIDResponseTypeToken,
            additionalParameters: additionalParameters
        )

        if let nonce = nonce {
            request.nonce = nonce
        }

        let session = OIDAuthState.authState(byPresenting: request, externalUserAgent: OIDExternalUserAgentIOS(presenting: UIApplication.shared.delegate?.window??.rootViewController)) { authorizationResponse, error in
            if let authorizationResponse = authorizationResponse {
                if exchangeCode {
                    self.performTokenExchange(with: authorizationResponse, serviceConfiguration: serviceConfiguration, clientId: clientId, clientSecret: clientSecret, result: result)
                } else {
                    result(FlutterAppAuth.processResponses(nil, authResponse: authorizationResponse))
                }
            } else if let error = error {
                FlutterAppAuth.finishWithError(AUTHORIZE_ERROR_CODE, message: FlutterAppAuth.formatMessage(with: error), result: result)
            }
        }

        return session
    }

    func performTokenExchange(with authorizationResponse: OIDAuthorizationResponse, serviceConfiguration: OIDServiceConfiguration, clientId: String, clientSecret: String, result: FlutterResult) {
        let tokenRequest = OIDTokenRequest(
            configuration: serviceConfiguration,
            grantType: OIDGrantTypeAuthorizationCode,
            authorizationCode: authorizationResponse.authorizationCode,
            redirectURL: authorizationResponse.request.redirectURL,
            clientID: clientId,
            clientSecret: clientSecret,
            scope: authorizationResponse.request.scope,
            refreshToken: nil,
            codeVerifier: authorizationResponse.request.codeVerifier
        )

        OIDAuthorizationService.perform(tokenRequest) { tokenResponse, error in
            if let tokenResponse = tokenResponse {
                result(FlutterAppAuth.processResponses(tokenResponse, authResponse: authorizationResponse))
            } else if let error = error {
                FlutterAppAuth.finishWithError(AUTHORIZE_AND_EXCHANGE_CODE_ERROR_CODE, message: FlutterAppAuth.formatMessage(with: error), result: result)
            }
        }
    }

    func performEndSessionRequest(_ serviceConfiguration: OIDServiceConfiguration, requestParameters: EndSessionRequestParameters, result: FlutterResult) -> OIDExternalUserAgentSession? {
        let endSessionRequest = OIDEndSessionRequest(
            configuration: serviceConfiguration,
            idTokenHint: requestParameters.idTokenHint,
            postLogoutRedirectURL: requestParameters.postLogoutRedirectUrl.flatMap { URL(string: $0) },
            state: requestParameters.state,
            additionalParameters: requestParameters.additionalParameters
        )

        let session = OIDExternalUserAgentSession.present(endSessionRequest, externalUserAgent: OIDExternalUserAgentIOS(presenting: UIApplication.shared.delegate?.window??.rootViewController)) { response, error in
            if let response = response {
                result(["state": response.state])
            } else if let error = error {
                FlutterAppAuth.finishWithError(END_SESSION_ERROR_CODE, message: FlutterAppAuth.formatMessage(with: error), result: result)
            }
        }

        return session
    }
}

