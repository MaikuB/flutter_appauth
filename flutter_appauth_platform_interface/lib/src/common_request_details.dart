import 'authorization_service_configuration.dart';

class CommonRequestDetails {
  /// The client id.
  String clientId;

  /// The issuer.
  String issuer;

  /// The URL of where the discovery document can be found.
  String discoveryUrl;

  /// The redirect URL.
  String redirectUrl;

  /// The request scopes.
  List<String> scopes;

  /// The details of the OAuth 2.0 endpoints that can be explicitly when discovery isn't used or not possible.
  AuthorizationServiceConfiguration serviceConfiguration;

  /// Additional parameters to include in the request.
  Map<String, String> additionalParameters;

  /// The connection type of the connection. Use ConnectionType.secure for HTTPS, ConnectionType.insecure for HTTP
  /// or ConnectionType.untrusted for HTTPS with untrusted certificates (for example, when using self-signed
  /// certificates for dev purposes)
  ///
  /// This property is only applicable to Android.
  int connectionType;
}
