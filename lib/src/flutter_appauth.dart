part of flutter_appauth;

class FlutterAppAuth {
  factory FlutterAppAuth() => _instance;

  final MethodChannel _channel;

  @visibleForTesting
  FlutterAppAuth.private(MethodChannel channel) : _channel = channel;

  static final FlutterAppAuth _instance = new FlutterAppAuth.private(
      const MethodChannel('crossingthestreams.io/flutter_appauth'));

  /// Convenience method for authorizing and then exchanging a token upon succesful authorization
  Future<AuthorizationTokenResponse> authorizeAndExchangeToken(
      AuthorizationTokenRequest request) async {
    var result = await _channel.invokeMethod(
        'authorizeAndExchangeToken', request.toMap());
    return AuthorizationTokenResponse(
        result['accessToken'],
        result['refreshToken'],
        result['accessTokenExpirationTime'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                result['accessTokenExpirationTime'].toInt()),
        result['idToken'],
        result['tokenType'],
        result['authorizationAdditionalParameters']?.cast<String, dynamic>(),
        result['tokenAdditionalParameters']?.cast<String, dynamic>());
  }

  /// For exchanging tokens
  Future<TokenResponse> token(TokenRequest request) async {
    var result = await _channel.invokeMethod('token', request.toMap());
    return TokenResponse(
        result['accessToken'],
        result['refreshToken'],
        result['accessTokenExpirationTime'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                result['accessTokenExpirationTime'].toInt()),
        result['idToken'],
        result['tokenType'],
        result['tokenAdditionalParameters']?.cast<String, String>());
  }
}
