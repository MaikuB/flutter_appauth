import 'package:flutter/services.dart';
import 'package:flutter_appauth_platform_interface/src/end_session_request.dart';
import 'package:flutter_appauth_platform_interface/src/end_session_response.dart';

import 'authorization_request.dart';
import 'authorization_response.dart';
import 'authorization_token_request.dart';
import 'authorization_token_response.dart';
import 'errors.dart';
import 'flutter_appauth_platform.dart';
import 'method_channel_mappers.dart';
import 'token_request.dart';
import 'token_response.dart';

const MethodChannel _channel =
    MethodChannel('crossingthestreams.io/flutter_appauth');

class MethodChannelFlutterAppAuth extends FlutterAppAuthPlatform {
  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async {
    final Map<dynamic, dynamic> result = await invokeMethod(
      'authorize',
      request.toMap(),
    );

    return AuthorizationResponse(
      authorizationCode: result['authorizationCode'],
      codeVerifier: result['codeVerifier'],
      nonce: result['nonce'],
      authorizationAdditionalParameters:
          result['authorizationAdditionalParameters']?.cast<String, dynamic>(),
    );
  }

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) async {
    final Map<dynamic, dynamic> result = await invokeMethod(
      'authorizeAndExchangeCode',
      request.toMap(),
    );

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
  Future<TokenResponse> token(TokenRequest request) async {
    final Map<dynamic, dynamic> result = await invokeMethod(
      'token',
      request.toMap(),
    );

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
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    final Map<dynamic, dynamic> result = await invokeMethod(
      'endSession',
      request.toMap(),
    );

    return EndSessionResponse(result['state']);
  }

  Future<Map<dynamic, dynamic>> invokeMethod(
      String method, dynamic arguments) async {
    try {
      return (await _channel.invokeMethod<Map<dynamic, dynamic>>(
          method, arguments))!;
    } on PlatformException catch (e) {
      if (e.details == null) {
        rethrow;
      }
      final Map<String?, String?>? errorDetails = _extractErrorDetails(
        e.details,
      );
      if (errorDetails == null) {
        rethrow;
      }

      // Ensures that the PlatformException remains the same as before the
      // introduction of custom exception handling so as to not break existing
      // usages.
      final dynamic legacyErrorDetails =
          errorDetails['legacy_error_details'] ?? errorDetails;
      final FlutterAppAuthPlatformErrorDetails parsedDetails =
          FlutterAppAuthPlatformErrorDetails.fromMap(errorDetails);

      if (errorDetails['user_did_cancel']?.toLowerCase().trim() == 'true') {
        throw FlutterAppAuthUserCancelledException(
          code: e.code,
          message: e.message,
          stacktrace: e.stacktrace,
          legacyDetails: legacyErrorDetails,
          platformErrorDetails: parsedDetails,
        );
      } else {
        throw FlutterAppAuthPlatformException(
          code: e.code,
          message: e.message,
          stacktrace: e.stacktrace,
          legacyDetails: legacyErrorDetails,
          platformErrorDetails: parsedDetails,
        );
      }
    }
  }

  Map<String?, String?>? _extractErrorDetails(dynamic details) {
    try {
      return details is Map ? details.cast<String?, String?>() : null;
    } catch (_) {
      return null;
    }
  }
}
