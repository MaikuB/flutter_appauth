import 'authorization_parameters.dart';
import 'authorization_service_configuration.dart';
import 'common_request_details.dart';

/// The details of an authorization request to get an authorization code.
class AuthorizationRequest extends CommonRequestDetails
    with AuthorizationParameters {
  AuthorizationRequest(
    String clientId,
    String redirectUrl, {
    String? loginHint,
    List<String>? scopes,
    AuthorizationServiceConfiguration? serviceConfiguration,
    Map<String, String>? additionalParameters,
    String? issuer,
    String? discoveryUrl,
    List<String>? promptValues,
    bool allowInsecureConnections = false,
    bool preferEphemeralSession = false,
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
  }
}
