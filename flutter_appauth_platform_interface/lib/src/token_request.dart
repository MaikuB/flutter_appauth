import 'authorization_service_configuration.dart';
import 'common_request_details.dart';
import 'grant_types.dart';

/// Details for a token exchange request
class TokenRequest with CommonRequestDetails {
  TokenRequest(
    String clientId,
    String redirectUrl, {
    this.clientSecret,
    List<String> scopes,
    AuthorizationServiceConfiguration serviceConfiguration,
    Map<String, String> additionalParameters,
    this.refreshToken,
    this.grantType,
    String issuer,
    String discoveryUrl,
    this.authorizationCode,
    this.codeVerifier,
    bool allowInsecureConnections = false,
  }) : assert(
            issuer != null ||
                discoveryUrl != null ||
                (serviceConfiguration?.authorizationEndpoint != null &&
                    serviceConfiguration?.tokenEndpoint != null),
            'Either the issuer, discovery URL or service configuration must be provided') {
    this.clientId = clientId;
    this.redirectUrl = redirectUrl;
    this.scopes = scopes;
    this.serviceConfiguration = serviceConfiguration;
    this.additionalParameters = additionalParameters;
    this.issuer = issuer;
    this.discoveryUrl = discoveryUrl;
    this.allowInsecureConnections = allowInsecureConnections;
  }

  /// The client secret
  final String clientSecret;

  /// The refresh token
  final String refreshToken;

  /// The grant type. This would be inferred if it hasn't been set based on if a refresh token or authorization code has been specified
  final String grantType;

  /// The authorization code
  final String authorizationCode;

  /// The code verifier to be sent with the authorization code. This should match the code verifier used when performing the authorization request
  final String codeVerifier;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = super.toMap();
    final String inferredGrantType = _inferGrantType();
    map['clientSecret'] = clientSecret;
    map['refreshToken'] = refreshToken;
    map['authorizationCode'] = authorizationCode;
    map['grantType'] = inferredGrantType;
    map['codeVerifier'] = codeVerifier;
    return map;
  }

  String _inferGrantType() {
    if (grantType != null) {
      return grantType;
    }
    if (refreshToken != null) {
      return GrantType.refreshToken;
    }
    if (authorizationCode != null) {
      return GrantType.authorizationCode;
    }

    throw ArgumentError.value(
        null, 'grantType', 'Grant type not specified and cannot be inferred');
  }
}
