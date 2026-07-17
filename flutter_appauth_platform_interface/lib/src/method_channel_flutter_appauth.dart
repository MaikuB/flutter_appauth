import 'package:flutter/services.dart';
import 'package:flutter_appauth_platform_interface/src/end_session_request.dart';
import 'package:flutter_appauth_platform_interface/src/end_session_response.dart';

import 'authorization_request.dart';
import 'authorization_resume_response.dart';
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

    return authorizationResponseFromResultMap(result);
  }

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) async {
    final Map<dynamic, dynamic> result = await invokeMethod(
      'authorizeAndExchangeCode',
      request.toMap(),
    );

    return authorizationTokenResponseFromResultMap(result);
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

  @override
  Future<AuthorizationResumeResponse?> resumePendingAuthorization() async {
    Map<dynamic, dynamic>? result;
    try {
      result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'resumePendingAuthorization',
      );
    } on PlatformException catch (e) {
      _mapAndThrowPlatformException(e);
    }

    if (result == null) {
      return null;
    }

    if (result.containsKey('accessToken')) {
      return AuthorizationResumeResponse.token(
        authorizationTokenResponseFromResultMap(result),
      );
    }

    return AuthorizationResumeResponse.authorize(
      authorizationResponseFromResultMap(result),
    );
  }

  Future<Map<dynamic, dynamic>> invokeMethod(
      String method, dynamic arguments) async {
    try {
      return (await _channel.invokeMethod<Map<dynamic, dynamic>>(
          method, arguments))!;
    } on PlatformException catch (e) {
      _mapAndThrowPlatformException(e);
    }
  }

  /// Maps a raw [PlatformException] from the method channel into one of the
  /// package's typed exceptions and throws it, or rethrows [e] unchanged if
  /// it doesn't carry the expected error details.
  Never _mapAndThrowPlatformException(PlatformException e) {
    if (e.details == null) {
      throw e;
    }
    final Map<String?, String?>? errorDetails = _extractErrorDetails(
      e.details,
    );
    if (errorDetails == null) {
      throw e;
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

  Map<String?, String?>? _extractErrorDetails(dynamic details) {
    try {
      return details is Map ? details.cast<String?, String?>() : null;
    } catch (_) {
      return null;
    }
  }
}
