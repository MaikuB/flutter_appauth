part of flutter_appauth;

/// Details required for an authorization request.
class AuthorizationRequest {
  final String clientId;
  final String issuer;
  final String discoveryUrl;
  final String redirectUrl;
  final String clientSecret;
  final String loginHint;
  final List<String> scopes;
  final AuthorizationServiceConfiguration serviceConfiguration;
  final Map<String, String> additionalParameters;

  AuthorizationRequest(this.clientId, this.redirectUrl,
      {this.issuer,
      this.discoveryUrl,
      this.clientSecret,
      this.scopes,
      this.serviceConfiguration,
      this.loginHint,
      this.additionalParameters})
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
      'scopes': scopes,
      'loginHint': loginHint,
      'serviceConfiguration': serviceConfiguration?.toMap(),
      'additionalParameters': additionalParameters
    };
  }
}
