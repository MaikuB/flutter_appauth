class ServiceConfiguration {
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String endSessionEndpoint;

  ServiceConfiguration(
      this.authorizationEndpoint, this.tokenEndpoint, this.endSessionEndpoint)
      : assert(tokenEndpoint != null && authorizationEndpoint != null,
            'Must specify both the authorization and token endpoints');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'tokenEndpoint': tokenEndpoint,
      'authorizationEndpoint': authorizationEndpoint,
      'endSessionEndpoint': endSessionEndpoint
    };
  }
}
