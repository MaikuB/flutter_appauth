part of flutter_appauth;

/// Details required for a combined authorization and code exchange request
class AuthorizationTokenRequest extends TokenRequest
    with _AuthorizationParameters {
  AuthorizationTokenRequest(String clientId, String redirectUrl,
      {String loginHint,
      String clientSecret,
      List<String> scopes,
      AuthorizationServiceConfiguration serviceConfiguration,
      Map<String, String> additionalParameters,
      String issuer,
      String discoveryUrl,
      List<String> promptValues})
      : super(clientId, redirectUrl,
            clientSecret: clientSecret,
            discoveryUrl: discoveryUrl,
            issuer: issuer,
            scopes: scopes,
            serviceConfiguration: serviceConfiguration,
            additionalParameters: additionalParameters) {
    this.loginHint = loginHint;
    this.promptValues = promptValues;
  }

  String _inferGrantType() {
    return grantType;
  }

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    return map;
  }
}
