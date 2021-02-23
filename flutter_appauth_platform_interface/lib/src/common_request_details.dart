import 'authorization_service_configuration.dart';

class CommonRequestDetails {
  /// The client id.
  late String clientId;

  /// The issuer.
  String? issuer;

  /// The URL of where the discovery document can be found.
  String? discoveryUrl;

  /// The redirect URL.
  late String redirectUrl;

  /// The request scopes.
  List<String>? scopes;

  /// The details of the OAuth 2.0 endpoints that can be explicitly when discovery isn't used or not possible.
  AuthorizationServiceConfiguration? serviceConfiguration;

  /// Additional parameters to include in the request.
  Map<String, String>? additionalParameters;

  /// Whether to allow non-HTTPS endpoints.
  ///
  /// This property is only applicable to Android.
  bool? allowInsecureConnections;
}
