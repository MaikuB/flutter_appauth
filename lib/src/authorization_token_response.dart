part of flutter_appauth;

class AuthorizationTokenResponse extends TokenResponse {
  final Map<String, dynamic> authorizationAdditionalParameters;

  AuthorizationTokenResponse(
      String accessToken,
      String refreshToken,
      int accessTokenExpirationTime,
      String idToken,
      String tokenType,
      this.authorizationAdditionalParameters,
      Map<String, dynamic> tokenAdditionalParameters)
      : super(accessToken, refreshToken, accessTokenExpirationTime, idToken,
            tokenType, tokenAdditionalParameters);
}
