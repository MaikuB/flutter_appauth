import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:flutter_appauth_platform_interface/src/accepted_authorization_service_configuration_details.dart';

/// Represents an end session request.
class EndSessionRequest with AcceptedAuthorizationServiceConfigurationDetails {
  EndSessionRequest({
    this.idTokenHint,
    this.postLogoutRedirectUrl,
    this.state,
    this.allowInsecureConnections = false,
    this.externalUserAgent = ExternalUserAgent.asWebAuthenticationSession,
    this.additionalParameters,
    String? issuer,
    String? discoveryUrl,
    AuthorizationServiceConfiguration? serviceConfiguration,
  }) {
    this.serviceConfiguration = serviceConfiguration;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
  }

  /// Represents the ID token previously issued to the user.
  ///
  /// Used to indicate the identity of the user requesting to be logged out.
  final String? idTokenHint;

  /// Represents the URL to redirect to after the logout operation has been
  /// completed.
  ///
  /// When specified, the [idTokenHint] must also be provided.
  final String? postLogoutRedirectUrl;

  final String? state;

  /// Whether to allow non-HTTPS endpoints.
  ///
  /// This property is only applicable to Android.
  bool allowInsecureConnections;

  /// Specifies the external user-agent to use.
  ExternalUserAgent? externalUserAgent;

  /// Additional parameters to include in the request.
  final Map<String, String>? additionalParameters;
}
