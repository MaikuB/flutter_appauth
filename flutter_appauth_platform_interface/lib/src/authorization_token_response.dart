import 'token_response.dart';

/// The details from making a successful combined authorization and token exchange request.
class AuthorizationTokenResponse extends TokenResponse {
  AuthorizationTokenResponse(
    String? accessToken,
    String? refreshToken,
    DateTime? accessTokenExpirationDateTime,
    String? idToken,
    String? tokenType,
    List<String>? scopes,
    this.authorizationAdditionalParameters,
    Map<String, dynamic>? tokenAdditionalParameters,
  ) : super(accessToken, refreshToken, accessTokenExpirationDateTime, idToken,
            tokenType, scopes, tokenAdditionalParameters);

  /// Contains additional parameters returned by the authorization server from making the authorization request.
  final Map<String, dynamic>? authorizationAdditionalParameters;
}
