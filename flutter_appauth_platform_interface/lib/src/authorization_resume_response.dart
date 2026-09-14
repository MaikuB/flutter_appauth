import 'authorization_response.dart';
import 'authorization_token_response.dart';

/// The result of resuming a pending authorization result that the native
/// platform received while no Dart call was awaiting it.
///
/// Depending on whether the original authorization flow was started with
/// `authorize()` or `authorizeAndExchangeCode()`, this is either
/// [AuthorizationResumeResponseAuthorize] or
/// [AuthorizationResumeResponseToken].
sealed class AuthorizationResumeResponse {
  const factory AuthorizationResumeResponse.authorize(
    AuthorizationResponse response,
  ) = AuthorizationResumeResponseAuthorize;

  const factory AuthorizationResumeResponse.token(
    AuthorizationTokenResponse response,
  ) = AuthorizationResumeResponseToken;
}

class AuthorizationResumeResponseAuthorize 
  implements AuthorizationResumeResponse {
  final AuthorizationResponse response;

  const AuthorizationResumeResponseAuthorize(this.response);
}

class AuthorizationResumeResponseToken implements AuthorizationResumeResponse {
  final AuthorizationTokenResponse response;

  const AuthorizationResumeResponseToken(this.response);
}
