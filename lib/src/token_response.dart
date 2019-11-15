/// Details from making a successful token exchange
class TokenResponse {
  TokenResponse(
      this.accessToken,
      this.refreshToken,
      this.accessTokenExpirationDateTime,
      this.idToken,
      this.tokenType,
      this.tokenAdditionalParameters);

  final String accessToken;

  final String refreshToken;

  final DateTime accessTokenExpirationDateTime;

  final String idToken;

  final String tokenType;

  final Map<String, dynamic> tokenAdditionalParameters;
}
