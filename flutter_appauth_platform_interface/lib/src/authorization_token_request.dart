import 'authorization_parameters.dart';
import 'external_agent_type.dart';
import 'grant_type.dart';
import 'token_request.dart';

/// Details required for a combined authorization and code exchange request
class AuthorizationTokenRequest extends TokenRequest
    with AuthorizationParameters {
  AuthorizationTokenRequest(
    super.clientId,
    super.redirectUrl, {
    String? loginHint,
    super.clientSecret,
    super.scopes,
    super.serviceConfiguration,
    super.additionalParameters,
    super.issuer,
    super.discoveryUrl,
    List<String>? promptValues,
    super.allowInsecureConnections,
    ExternalAgentType preferredExternalAgent =
        ExternalAgentType.asWebAuthenticationSession,
    super.nonce,
    String? responseMode,
  }) : super(
          grantType: GrantType.authorizationCode,
        ) {
    this.loginHint = loginHint;
    this.promptValues = promptValues;
    this.preferredExternalAgent = preferredExternalAgent;
    this.responseMode = responseMode;
  }
}
