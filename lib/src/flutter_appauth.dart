part of flutter_appauth;

class FlutterAppAuth {
  factory FlutterAppAuth() => _instance;

  final MethodChannel _channel;

  @visibleForTesting
  FlutterAppAuth.private(MethodChannel channel) : _channel = channel;

  static final FlutterAppAuth _instance = new FlutterAppAuth.private(
      const MethodChannel('crossingthestreams.io/flutter_appauth'));

  /// Attempts to issue an authorization request and exchange for a token
  Future<AuthorizationTokenResponse> authorize(
      AuthorizationRequest request) async {
    var result = await _channel.invokeMethod('authorize', request.toMap());
    return AuthorizationTokenResponse(
        result['accessToken'],
        result['refreshToken'],
        result['accessTokenExpirationTime'],
        result['idToken'],
        result['tokenType'],
        result['authorizationAdditionalParameters']?.cast<String, dynamic>(),
        result['tokenAdditionalParameters']?.cast<String, dynamic>());
  }

  /// For refreshing tokens
  Future<TokenResponse> refresh(RefreshRequest request) async {
    var result = await _channel.invokeMethod('refresh', request.toMap());
    return TokenResponse(
        result['accessToken'],
        result['refreshToken'],
        result['accessTokenExpirationTime'],
        result['idToken'],
        result['tokenType'],
        result['tokenAdditionalParameters']?.cast<String, String>());
  }
}
