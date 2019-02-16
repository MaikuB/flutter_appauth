part of flutter_appauth;

/// Details required for a combined authorization and code exchange request
class AuthorizationTokenRequest extends TokenRequest {
  /// The login hint to send to the authorization server
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
            discoveryUrl: discoveryUrl,
            issuer: issuer,
            scopes: scopes,
            serviceConfiguration: serviceConfiguration,
            additionalParameters: additionalParameters);

  String _inferGrantType() {
    return grantType;
  }

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['loginHint'] = loginHint;
    return map;
  }
}
