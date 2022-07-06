import 'authorization_parameters.dart';
import 'authorization_service_configuration.dart';
import 'common_request_details.dart';

/// The details of an authorization request to get an authorization code.
class AuthorizationRequest extends CommonRequestDetails
    with AuthorizationParameters {
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
    bool preferEphemeralSession = false,
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
    this.loginHint = loginHint;
    this.promptValues = promptValues;
    this.allowInsecureConnections = allowInsecureConnections;
    this.preferEphemeralSession = preferEphemeralSession;
    this.nonce = nonce;
    this.responseMode = responseMode;
    assertConfigurationInfo();
  }
}
