class AuthorizationServiceConfiguration {
  const AuthorizationServiceConfiguration({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    this.endSessionEndpoint,
  });

  final String authorizationEndpoint;

  final String tokenEndpoint;

  final String? endSessionEndpoint;
}
