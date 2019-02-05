part of flutter_appauth;

/// Details for refreshing a token
class RefreshRequest extends AuthorizationRequest {
  final String refreshToken;

  RefreshRequest(String clientId, String redirectUrl, this.refreshToken,
      {String issuer,
      String discoveryUrl,
      String clientSecret,
      List<String> scopes,
      AuthorizationServiceConfiguration serviceConfiguration,
      Map<String, String> additionalParameters})
      : super(clientId, redirectUrl,
            issuer: issuer,
            discoveryUrl: discoveryUrl,
            clientSecret: clientSecret,
            scopes: scopes,
            serviceConfiguration: serviceConfiguration,
            additionalParameters: additionalParameters);

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['refreshToken'] = refreshToken;
    return map;
  }
}
