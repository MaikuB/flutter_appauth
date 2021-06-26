class AuthorizationServiceConfiguration {
  const AuthorizationServiceConfiguration({
    this.authorizationEndpoint,
    this.tokenEndpoint,
    this.endSessionEndpoint,
  });

  final String? authorizationEndpoint;

  final String? tokenEndpoint;

  final String? endSessionEndpoint;
}
