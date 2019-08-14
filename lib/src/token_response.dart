/// Details from making a successful token exchange
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final DateTime accessTokenExpirationDateTime;
  final String idToken;
  final String tokenType;
  final Map<String, dynamic> tokenAdditionalParameters;

  TokenResponse(
      this.accessToken,
      this.refreshToken,
      this.accessTokenExpirationDateTime,
      this.idToken,
      this.tokenType,
      this.tokenAdditionalParameters);
}
