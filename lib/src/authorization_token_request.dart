part of flutter_appauth;

/// Details required for a combined authorization and token exchange request
class AuthorizationTokenRequest extends TokenRequest {
  final String loginHint;

  AuthorizationTokenRequest(String clientId, String redirectUrl,
      {this.loginHint,
      String clientSecret,
      List<String> scopes,
      AuthorizationServiceConfiguration serviceConfiguration,
      Map<String, String> additionalParameters,
      String issuer,
      String discoveryUrl})
      : super(clientId, redirectUrl,
            clientSecret: clientSecret,
            scopes: scopes,
            serviceConfiguration: serviceConfiguration,
            additionalParameters: additionalParameters);

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['loginHint'] = loginHint;
    return map;
  }
}
