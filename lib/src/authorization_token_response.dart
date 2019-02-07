part of flutter_appauth;

/// The details from making a successful combined authorization and token exchange request
class AuthorizationTokenResponse extends TokenResponse {
  final Map<String, dynamic> authorizationAdditionalParameters;

  AuthorizationTokenResponse(
      String accessToken,
      String refreshToken,
      DateTime accessTokenExpirationDateTime,
      String idToken,
      String tokenType,
      this.authorizationAdditionalParameters,
      Map<String, dynamic> tokenAdditionalParameters)
      : super(accessToken, refreshToken, accessTokenExpirationDateTime, idToken,
            tokenType, tokenAdditionalParameters);
}
