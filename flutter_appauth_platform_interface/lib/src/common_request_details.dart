import 'accepted_authorization_service_configuration_details.dart';

class CommonRequestDetails
    with AcceptedAuthorizationServiceConfigurationDetails {
  /// The client id.
  late String clientId;

  /// The redirect URL.
  late String redirectUrl;

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
