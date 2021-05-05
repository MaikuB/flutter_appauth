import 'authorization_service_configuration.dart';
import 'common_request_details.dart';

class EndSessionRequest with CommonRequestDetails {
  EndSessionRequest(
    String issuer,
    this.idTokenHint,
    String discoveryUrl,
    this.postLogoutRedirectURL,
    AuthorizationServiceConfiguration serviceConfiguration, {
    Map<String, String> additionalParameters = const {},
    bool allowInsecureConnections = false,
  }) {
    this.serviceConfiguration = serviceConfiguration;
    this.additionalParameters = additionalParameters;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
    this.allowInsecureConnections = allowInsecureConnections;
  }

  final String idTokenHint;
  final String postLogoutRedirectURL;
}
