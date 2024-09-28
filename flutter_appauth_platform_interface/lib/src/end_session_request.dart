import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:flutter_appauth_platform_interface/src/accepted_authorization_service_configuration_details.dart';

/// Represents an end session request.
class EndSessionRequest with AcceptedAuthorizationServiceConfigurationDetails {
  EndSessionRequest({
    this.idTokenHint,
    this.postLogoutRedirectUrl,
    this.state,
    this.allowInsecureConnections = false,
    this.preferredExternalAgent = ExternalAgentType.asWebAuthenticationSession,
    this.additionalParameters,
    String? issuer,
    String? discoveryUrl,
    AuthorizationServiceConfiguration? serviceConfiguration,
  }) : assert((idTokenHint == null && postLogoutRedirectUrl == null) ||
            (idTokenHint != null && postLogoutRedirectUrl != null)) {
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

  /// Decides what type of external agent to use for the authorization flow.
  /// ASWebAuthenticationSession is the default for iOS 12 and above.
  /// EphemeralSession is not sharing browser data
  /// with the user's normal browser session but not keeping the cache
  /// SFSafariViewController is not sharing browser data
  /// with the user's normal browser session but keeping the cache.
  /// This property is only applicable to iOS versions 13 and above.
  /// ExternalAgentType? preferredExternalAgent;
  ///
  /// Sign in and out must have the same type.
  ExternalAgentType? preferredExternalAgent;

  final Map<String, String>? additionalParameters;
}
