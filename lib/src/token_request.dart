part of flutter_appauth;

/// Details for a token exchange request
class TokenRequest {
  final String clientId;
  final String redirectUrl;
  final String clientSecret;
  final List<String> scopes;
  final AuthorizationServiceConfiguration serviceConfiguration;
  final Map<String, String> additionalParameters;
  final String refreshToken;
  final String grantType;
  final String issuer;
  final String discoveryUrl;

  TokenRequest(this.clientId, this.redirectUrl,
      {this.clientSecret,
      this.scopes,
      this.serviceConfiguration,
      this.additionalParameters,
      this.refreshToken,
      this.grantType,
      this.issuer,
      this.discoveryUrl})
      : assert(
            (issuer != null &&
                    discoveryUrl == null &&
                    serviceConfiguration == null) ||
                (issuer == null &&
                    discoveryUrl != null &&
                    serviceConfiguration == null) ||
                (issuer == null &&
                    discoveryUrl == null &&
                    serviceConfiguration?.authorizationEndpoint != null &&
                    serviceConfiguration?.tokenEndpoint != null),
            'Either the issuer, discovery URL or service configuration must be provided');

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'clientId': clientId,
      'issuer': issuer,
      'discoveryUrl': discoveryUrl,
      'redirectUrl': redirectUrl,
      'clientSecret': clientSecret,
      'refreshToken': refreshToken,
      'grantType': grantType,
      'scopes': scopes,
      'serviceConfiguration': serviceConfiguration?.toMap(),
      'additionalParameters': additionalParameters
    };
  }
}
