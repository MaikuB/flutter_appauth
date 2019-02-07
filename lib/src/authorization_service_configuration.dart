part of flutter_appauth;

class AuthorizationServiceConfiguration {
  final String authorizationEndpoint;
  final String tokenEndpoint;

  AuthorizationServiceConfiguration(
      this.authorizationEndpoint, this.tokenEndpoint)
      : assert(tokenEndpoint != null && authorizationEndpoint != null,
            'Must specify both the authorization and token endpoints');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tokenEndpoint': tokenEndpoint,
      'authorizationEndpoint': authorizationEndpoint
    };
  }
}
