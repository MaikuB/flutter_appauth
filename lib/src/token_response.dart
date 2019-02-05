part of flutter_appauth;

class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int accessTokenExpirationTime;
  final String idToken;
  final String tokenType;
  final Map<String, dynamic> tokenAdditionalParameters;

  TokenResponse(
      this.accessToken,
      this.refreshToken,
      this.accessTokenExpirationTime,
      this.idToken,
      this.tokenType,
      this.tokenAdditionalParameters);
}
