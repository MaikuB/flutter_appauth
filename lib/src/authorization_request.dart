part of flutter_appauth;

/// The details of an authorization request to get an authorization code
class AuthorizationRequest with _CommonRequestDetails {
  final String loginHint;
  AuthorizationRequest(String clientId, String redirectUrl,
      {this.loginHint,
      List<String> scopes,
      AuthorizationServiceConfiguration serviceConfiguration,
      Map<String, String> additionalParameters,
      String issuer,
      String discoveryUrl}) {
    this.clientId = clientId;
    this.redirectUrl = redirectUrl;
    this.scopes = scopes;
    this.serviceConfiguration = serviceConfiguration;
    this.additionalParameters = additionalParameters;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
  }

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['loginHint'] = loginHint;
    return map;
  }
}
