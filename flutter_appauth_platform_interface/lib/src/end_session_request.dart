import 'authorization_service_configuration.dart';

/// The details of an end_session request to initiate a logout
class EndSessionRequest {
  EndSessionRequest(this.issuer, this.idTokenHint, this.discoveryUrl,
      this.redirectUrl, this.serviceConfiguration,
      {this.additionalParameters});

  String issuer;

  String idTokenHint;

  String discoveryUrl;

  String redirectUrl;

  // The details of the OAuth 2.0 endpoints that can be explicitly when discovery isn't used or not possible
  AuthorizationServiceConfiguration serviceConfiguration;

  /// Additional parameters to include in the request
  Map<String, String> additionalParameters;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'issuer': issuer,
      'idTokenHint': idTokenHint,
      'discoveryUrl': discoveryUrl,
      'redirectUrl': redirectUrl,
      'serviceConfiguration': serviceConfiguration?.toMap(),
      'additionalParameters': additionalParameters,
    };
  }
}
