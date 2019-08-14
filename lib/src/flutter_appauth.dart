import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'authorization_request.dart';
import 'authorization_response.dart';
import 'authorization_token_request.dart';
import 'authorization_token_response.dart';
import 'token_request.dart';
import 'token_response.dart';

class FlutterAppAuth {
  factory FlutterAppAuth() => _instance;

  final MethodChannel _channel;

  @visibleForTesting
  FlutterAppAuth.private(MethodChannel channel) : _channel = channel;

  static final FlutterAppAuth _instance = new FlutterAppAuth.private(
      const MethodChannel('crossingthestreams.io/flutter_appauth'));

  /// Convenience method for authorizing and then exchanges code
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) async {
    var result = await _channel.invokeMethod(
        'authorizeAndExchangeCode', request.toMap());
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

  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async {
    var result = await _channel.invokeMethod('authorize', request.toMap());
    return AuthorizationResponse(
        result['authorizationCode'],
        result['codeVerifier'],
        result['authorizationAdditionalParameters']?.cast<String, dynamic>());
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
