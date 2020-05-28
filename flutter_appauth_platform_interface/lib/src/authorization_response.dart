class AuthorizationResponse {
  AuthorizationResponse(
    this.authorizationCode,
    this.codeVerifier,
    this.authorizationAdditionalParameters,
  );

  /// The authorization code.
  final String authorizationCode;

  /// The code verifier generated by AppAuth when issue the authorization request. Use this when exchanging the [authorizationCode] for a token.
  final String codeVerifier;

  /// Additional parameters included in the response.
  final Map<String, dynamic> authorizationAdditionalParameters;
}
