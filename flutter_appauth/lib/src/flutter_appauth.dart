import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';

class FlutterAppAuth {
  const FlutterAppAuth();

  /// Convenience method for authorizing and then exchanges code
  Future<AuthorizationTokenResponse?> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) {
    return FlutterAppAuthPlatform.instance.authorizeAndExchangeCode(request);
  }

  /// Sends an authorization request
  Future<AuthorizationResponse?> authorize(AuthorizationRequest request) {
    return FlutterAppAuthPlatform.instance.authorize(request);
  }

  /// For exchanging tokens
  Future<TokenResponse?> token(TokenRequest request) {
    return FlutterAppAuthPlatform.instance.token(request);
  }

  Future<EndSessionResponse?> endSession(EndSessionRequest request) {
    return FlutterAppAuthPlatform.instance.endSession(request);
  }
}
