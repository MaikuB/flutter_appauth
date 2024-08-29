import 'package:flutter/services.dart';

/// The details of an error thrown from the underlying
/// platform's AppAuth SDK
class FlutterAppAuthPlatformErrorDetails {
  FlutterAppAuthPlatformErrorDetails({
    this.type,
    this.code,
    this.error,
    this.errorDescription,
    this.errorUri,
    this.domain,
    this.rootCauseDebugDescription,
    this.errorDebugDescription,
  });

  /// The type of error.
  ///
  /// On iOS/macOS: one of the domain values from [here](https://github.com/openid/AppAuth-iOS/blob/c89ed571ae140f8eb1142735e6e23d7bb8c34cb2/Sources/AppAuthCore/OIDError.m#L31).
  /// On Android: one of the type codes from [here](https://github.com/openid/AppAuth-Android/blob/c6137b7db306d9c097c0d5763f3fb944cd0122d2/library/java/net/openid/appauth/AuthorizationException.java).
  ///
  /// It's recommended to not use this unless needed. In most cases, errors
  /// can be handled using the [error] property.
  final String? type;

  /// An error code from the platform's AppAuth SDK.
  ///
  /// On iOS/macOS: depending on the error type, it will be values from [here](https://github.com/openid/AppAuth-iOS/blob/c89ed571ae140f8eb1142735e6e23d7bb8c34cb2/Sources/AppAuthCore/OIDError.h).
  /// On Android: one of the codes defined [here](https://github.com/openid/AppAuth-Android/blob/c6137b7db306d9c097c0d5763f3fb944cd0122d2/library/java/net/openid/appauth/AuthorizationException.java#L158).
  ///
  /// It's recommended to not use this unless needed. In most cases, errors
  /// can be handled using the [error] property.
  final String? code;

  /// Error from the authorization server.
  ///
  /// For 400 errors from the authorization server, this is corresponds to the
  /// `error` parameter as defined in the OAuth 2.0 framework [here](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2).
  /// Otherwise a short error describing what happened.
  ///
  /// The [FlutterAppAuthOAuthError] class contains string constants for
  /// the standard error codes that could used by applications to determine the
  /// nature of the error.
  ///
  /// Note that authorization servers may return custom error codes that are not
  /// defined in the OAuth 2.0 framework.
  final String? error;

  /// Short, human readable error description.
  ///
  /// This may come from the authhorization server that it correspond to the
  /// `error_description` parameter as defined in the OAuth
  /// 2.0 [here](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2).
  /// Otherwise, this is populated by the underlying platform's AppAuth SDK.
  final String? errorDescription;

  /// Error URI from the authorization server.
  ///
  /// Corresponds to the `error_uri` parameter defined in the OAuth 2.0
  /// framework [here](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2)
  final String? errorUri;

  /// Error domain from the AppAuth iOS SDK.
  ///
  /// Only populated on iOS/macOS.
  final String? domain;

  /// A debug description of the error from the platform's AppAuth SDK
  final String? errorDebugDescription;

  /// A debug description of the underlying cause of the error from the
  /// platform's AppAuth SDK
  final String? rootCauseDebugDescription;

  @override
  String toString() {
    return 'FlutterAppAuthPlatformErrorDetails(type: $type,\n code: $code,\n '
        'error: $error,\n errorDescription: $errorDescription,\n '
        'errorUri: $errorUri,\n domain $domain,\n'
        'rootCauseDebugDescription: $rootCauseDebugDescription,\n '
        'errorDebugDescription: $errorDebugDescription)';
  }

  static FlutterAppAuthPlatformErrorDetails fromMap(Map<String?, String?> map) {
    return FlutterAppAuthPlatformErrorDetails(
      type: map['type'],
      code: map['code'],
      error: map['error'],
      errorDescription: map['error_description'],
      errorUri: map['error_uri'],
      domain: map['domain'],
      rootCauseDebugDescription: map['root_cause_debug_description'],
      errorDebugDescription: map['error_debug_description'],
    );
  }
}

/// Thrown when an authorization request has been cancelled as a result of a
/// user closing the browser.
class FlutterAppAuthUserCancelledException extends PlatformException {
  FlutterAppAuthUserCancelledException({
    required super.code,
    super.message,
    dynamic legacyDetails,
    super.stacktrace,
    required this.platformErrorDetails,
  }) : super(
          details: legacyDetails,
        );

  /// Details of the error from the underlying platform's AppAuth SDK.
  final FlutterAppAuthPlatformErrorDetails platformErrorDetails;

  @override
  String toString() {
    return 'FlutterAppAuthUserCancelledException{platformErrorDetails: '
        '$platformErrorDetails}';
  }
}

/// Thrown to indicate an interaction failed in the `package:flutter_appauth`
/// plugin.
class FlutterAppAuthPlatformException extends PlatformException {
  FlutterAppAuthPlatformException({
    required super.code,
    super.message,
    dynamic legacyDetails,
    super.stacktrace,
    required this.platformErrorDetails,
  }) : super(
          details: legacyDetails,
        );

  /// Details of the error from the underlying platform's AppAuth SDK.
  final FlutterAppAuthPlatformErrorDetails platformErrorDetails;
}

/// Represents OAuth error codes that can be returned by the authorization
/// server.
///
/// These are the standard error codes defined in the OAuth 2.0 framework
/// [here](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2).
class FlutterAppAuthOAuthError {
  static const String invalidRequest = 'invalid_request';
  static const String invalidClient = 'invalid_client';
  static const String invalidGrant = 'invalid_grant';
  static const String unauthorizedClient = 'unauthorized_client';
  static const String unsupportedGrantType = 'unsupported_grant_type';
  static const String invalidScope = 'invalid_scope';
}
