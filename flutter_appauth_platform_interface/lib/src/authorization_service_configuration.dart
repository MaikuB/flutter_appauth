class AuthorizationServiceConfiguration {
  const AuthorizationServiceConfiguration(
    this.authorizationEndpoint,
    this.tokenEndpoint,
  );

  final String authorizationEndpoint;

  final String tokenEndpoint;
}
