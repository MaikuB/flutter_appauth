import 'package:flutter/services.dart';
import 'package:flutter_appauth_platform_interface/src/end_session_request.dart';
import 'package:flutter_appauth_platform_interface/src/end_session_response.dart';

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
      authorizationCode: result['authorizationCode'],
      codeVerifier: result['codeVerifier'],
      nonce: result['nonce'],
      authorizationAdditionalParameters:
          result['authorizationAdditionalParameters']?.cast<String, dynamic>(),
    );
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
        result['scopes']?.cast<String>(),
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
        result['scopes']?.cast<String>(),
        result['tokenAdditionalParameters']?.cast<String, dynamic>());
  }

  @override
  Future<EndSessionResponse?> endSession(EndSessionRequest request) async {
    final Map<dynamic, dynamic>? result =
        await _channel.invokeMethod('endSession', request.toMap());
    if (result == null) {
      return null;
    }
    return EndSessionResponse(result['state']);
  }
}
