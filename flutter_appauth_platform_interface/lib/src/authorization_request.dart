import 'authorization_parameters.dart';
import 'authorization_service_configuration.dart';
import 'common_request_details.dart';
import 'external_user_agent.dart';

/// The details of an authorization request to get an authorization code.
class AuthorizationRequest extends CommonRequestDetails with AuthorizationParameters {
  AuthorizationRequest(
    String clientId,
    String redirectUrl, {
    String? issuer,
    String? discoveryUrl,
    AuthorizationServiceConfiguration? serviceConfiguration,
    String? loginHint,
    List<String>? scopes,
    Map<String, String>? additionalParameters,
    List<String>? promptValues,
    bool allowInsecureConnections = false,
    ExternalUserAgent externalUserAgent = ExternalUserAgent.asWebAuthenticationSession,
    String? nonce,
    String? responseMode,
  }) {
    this.clientId = clientId;
    this.redirectUrl = redirectUrl;
    this.scopes = scopes;
    this.serviceConfiguration = serviceConfiguration;
    this.additionalParameters = additionalParameters;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
    if (loginHint?.isEmpty == true) {
      this.loginHint = null;
    } else {
      this.loginHint = loginHint;
    }

    this.promptValues = promptValues;
    this.allowInsecureConnections = allowInsecureConnections;
    this.externalUserAgent = externalUserAgent;
    this.nonce = nonce;
    this.responseMode = responseMode;
    assertConfigurationInfo();
  }
}
