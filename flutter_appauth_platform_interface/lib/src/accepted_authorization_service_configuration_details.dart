import 'authorization_service_configuration.dart';

mixin AcceptedAuthorizationServiceConfigurationDetails {
  /// The issuer.
  String? issuer;

  /// The URL of where the discovery document can be found.
  String? discoveryUrl;

  /// The details of the OAuth 2.0 endpoints that can be explicitly provided when discovery isn't used or not possible.
  AuthorizationServiceConfiguration? serviceConfiguration;

  void assertConfigurationInfo() {
    assert(
        issuer != null || discoveryUrl != null || serviceConfiguration != null,
        'Either the issuer, discovery URL or service configuration must be provided');
  }
}
