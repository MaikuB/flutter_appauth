import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';

class EndSessionRequest {
  final String idTokenHint;
  final String postLogoutRedirectUrl;
  final String? discoveryUrl;
  final AuthorizationServiceConfiguration? serviceConfiguration;

  const EndSessionRequest(
    this.idTokenHint,
    this.postLogoutRedirectUrl, {
    this.discoveryUrl,
    this.serviceConfiguration,
  });
}
