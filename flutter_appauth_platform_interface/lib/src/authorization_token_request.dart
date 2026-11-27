import 'authorization_parameters.dart';
import 'external_user_agent.dart';
import 'grant_type.dart';
import 'safari_view_controller_presentation_style.dart';
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
    ExternalUserAgent externalUserAgent =
        ExternalUserAgent.asWebAuthenticationSession,
    SafariViewControllerPresentationStyle
        safariViewControllerPresentationStyle =
        SafariViewControllerPresentationStyle.formSheet,
    super.nonce,
    String? responseMode,
  }) : super(
          grantType: GrantType.authorizationCode,
        ) {
    this.loginHint = loginHint;
    this.promptValues = promptValues;
    this.externalUserAgent = externalUserAgent;
    this.safariViewControllerPresentationStyle =
        safariViewControllerPresentationStyle;
    this.responseMode = responseMode;
  }
}
