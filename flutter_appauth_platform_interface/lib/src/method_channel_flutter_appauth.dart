import 'package:flutter/services.dart';

import 'authorization_request.dart';
import 'authorization_response.dart';
import 'authorization_token_request.dart';
import 'authorization_token_response.dart';
import 'flutter_appauth_platform.dart';
import 'method_channel_mappers.dart';
import 'token_request.dart';
import 'token_response.dart';

const MethodChannel _channel =
    MethodChannel('crossingthestreams.io/flutter_appauth');

class MethodChannelFlutterAppAuth extends FlutterAppAuthPlatform {
  @override
  Future<AuthorizationResponse?> authorize(AuthorizationRequest request) async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('authorize', request.toMap());
    if (result == null) {
      return null;
    }
    return AuthorizationResponse(
        result['authorizationCode'],
        result['codeVerifier'],
        result['authorizationAdditionalParameters']?.cast<String, dynamic>());
  }

  @override
  Future<AuthorizationTokenResponse?> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) async {
    final Map<dynamic, dynamic>? result = await _channel.invokeMethod(
        'authorizeAndExchangeCode', request.toMap());
    if (result == null) {
      return null;
    }
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

  @override
  Future<TokenResponse?> token(TokenRequest request) async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('token', request.toMap());
    if (result == null) {
      return null;
    }
    return TokenResponse(
        result['accessToken'],
        result['refreshToken'],
        result['accessTokenExpirationTime'] == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(
                result['accessTokenExpirationTime'].toInt()),
        result['idToken'],
        result['tokenType'],
        result['tokenAdditionalParameters']?.cast<String, dynamic>());
  }
}
