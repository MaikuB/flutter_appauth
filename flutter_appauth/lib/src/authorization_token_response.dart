import 'token_response.dart';

/// The details from making a successful combined authorization and token exchange request
class AuthorizationTokenResponse extends TokenResponse {
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

  final Map<String, dynamic> authorizationAdditionalParameters;
}
