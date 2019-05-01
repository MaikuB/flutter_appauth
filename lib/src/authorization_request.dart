part of flutter_appauth;

/// The details of an authorization request to get an authorization code
class AuthorizationRequest extends _CommonRequestDetails
    with _AuthorizationParameters {
  AuthorizationRequest(String clientId, String redirectUrl,
      {String loginHint,
      List<String> scopes,
      AuthorizationServiceConfiguration serviceConfiguration,
      Map<String, String> additionalParameters,
      String issuer,
      String discoveryUrl,
      List<String> promptValues}) {
    this.clientId = clientId;
    this.redirectUrl = redirectUrl;
    this.scopes = scopes;
    this.serviceConfiguration = serviceConfiguration;
    this.additionalParameters = additionalParameters;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
    this.loginHint = loginHint;
    this.promptValues = promptValues;
  }

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    return map;
  }
}
