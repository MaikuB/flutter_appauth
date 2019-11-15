import 'authorization_service_configuration.dart';
import 'mappable.dart';

class CommonRequestDetails implements Mappable {
  /// The client id
  String clientId;

  /// The issuer
  String issuer;

  /// The URL of where the discovery document can be found
  String discoveryUrl;

  /// The redirect URL
  String redirectUrl;

  /// The request scopes
  List<String> scopes;

  /// The details of the OAuth 2.0 endpoints that can be explicitly when discovery isn't used or not possible
  AuthorizationServiceConfiguration serviceConfiguration;

  /// Additional parameters to include in the request
  Map<String, String> additionalParameters;

  /// Whether to allow non-HTTPS endpoints (only applicable on Android)
  bool allowInsecureConnections;

  @override
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clientId': clientId,
      'issuer': issuer,
      'discoveryUrl': discoveryUrl,
      'redirectUrl': redirectUrl,
      'scopes': scopes,
      'serviceConfiguration': serviceConfiguration?.toMap(),
      'additionalParameters': additionalParameters,
      'allowInsecureConnections': allowInsecureConnections
    };
  }
}
