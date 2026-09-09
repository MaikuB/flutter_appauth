import 'accepted_authorization_service_configuration_details.dart';

class CommonRequestDetails
    with AcceptedAuthorizationServiceConfigurationDetails {
  /// The client id.
  late String clientId;

  /// The redirect URL.
  late String redirectUrl;

  /// An optional HTTPS proxy redirect URL.
  ///
  /// Some OAuth servers only allow HTTPS redirect URIs. When set, this URL is
  /// sent to the OAuth server as the `redirect_uri` parameter, while
  /// [redirectUrl] (the custom-scheme deep link) is used to intercept the
  /// callback. Token exchange also uses [proxyRedirectUrl] so that it matches
  /// what was sent in the authorization request.
  String? proxyRedirectUrl;

  /// The request scopes.
  List<String>? scopes;

  /// The nonce.
  String? nonce;

  /// Additional parameters to include in the request.
  Map<String, String>? additionalParameters;

  /// Whether to allow non-HTTPS endpoints.
  ///
  /// This property is only applicable to Android.
  bool? allowInsecureConnections;
}
