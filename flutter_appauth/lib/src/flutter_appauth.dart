import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'end_session_request.dart';
import 'end_session_response.dart';

class FlutterAppAuth {
  /// Convenience method for authorizing and then exchanges code
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) {
    return FlutterAppAuthPlatform.instance.authorizeAndExchangeCode(request);
  }

  /// Sends an authorization request
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) {
    return FlutterAppAuthPlatform.instance.authorize(request);
  }

  /// For exchanging tokens
  Future<TokenResponse> token(TokenRequest request) {
    return FlutterAppAuthPlatform.instance.token(request);
  }

  /// For logging out
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    var result = await _channel.invokeMethod('endSession', request.toMap());
    return EndSessionResponse(
      result['state'],
      result['endSessionAdditionalParameters']?.cast<String, dynamic>(),
    );
  }
}
