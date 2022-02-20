/// Details from making a successful token exchange.
class TokenResponse {
  TokenResponse(
    this.accessToken,
    this.refreshToken,
    this.accessTokenExpirationDateTime,
    this.idToken,
    this.tokenType,
    this.scopes,
    this.tokenAdditionalParameters,
  );

  /// The access token returned by the authorization server.
  final String? accessToken;

  /// The refresh token returned by the authorization server.
  final String? refreshToken;

  /// Indicates when [accessToken] will expire.
  ///
  /// To ensure applications have continue to use valid access tokens, they
  /// will generally use the refresh token to get a new access token
  /// before it expires.
  final DateTime? accessTokenExpirationDateTime;

  /// The id token returned by the authorization server.
  final String? idToken;

  /// The type of token returned by the authorization server.
  final String? tokenType;

  /// Scopes of the access token. If scopes are identical to those originally requested, then this value is optional.
  final List<String>? scopes;

  /// Contains additional parameters returned by the authorization server from making the token request.
  final Map<String, dynamic>? tokenAdditionalParameters;
}
