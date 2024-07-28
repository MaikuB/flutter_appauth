import 'package:flutter/services.dart';

/// The details of an error thrown from the underlying
/// platform's AppAuth SDK
class FlutterAppAuthPlatformErrorDetails {

  FlutterAppAuthPlatformErrorDetails({
    required this.type,
    required this.code,
    required this.error,
    required this.errorDescription,
    required this.errorUri,
    required this.domain,
    required this.rootCauseDebugDescription,
    required this.errorDebugDescription,
    required this.userDidCancel,
  });

  /// Type of the error
  ///
  /// On iOS: One of the domain values here: 
  ///         https://github.com/openid/AppAuth-iOS/blob/c89ed571ae140f8eb1142735e6e23d7bb8c34cb2/Sources/AppAuthCore/OIDError.m#L31
  /// On Android: One of the type codes here: 
  ///         https://github.com/openid/AppAuth-Android/blob/c6137b7db306d9c097c0d5763f3fb944cd0122d2/library/java/net/openid/appauth/AuthorizationException.java
  /// Recommend not using this field unless you really have to, see `error` field below.
  final String? type;

  /// Error code
  ///
  /// On iOS: One of the enum values defined here depending on the error type
  ///         https://github.com/openid/AppAuth-iOS/blob/c89ed571ae140f8eb1142735e6e23d7bb8c34cb2/Sources/AppAuthCore/OIDError.h
  /// On Android: One of the codes defined here:
  ///          https://github.com/openid/AppAuth-Android/blob/c6137b7db306d9c097c0d5763f3fb944cd0122d2/library/java/net/openid/appauth/AuthorizationException.java#L158
  /// Recommend not using this field unless you really have to, see `error` field below.
  final String? code;

  /// Error from the Authorization server
  ///
  /// For 400 errors from the Authorization server, this is error defined here: https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
  /// e.g "invalid_grant"
  /// Otherwise a short error describing what happened.
  final String? error;

  /// Error description from the Authorization server
  ///
  /// Short, human readable error description.
  final String? errorDescription;

  /// Error uri from the Authorization server
  ///
  /// The error URI from the https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
  /// This is currently *only* populated on Android.
  final String? errorUri;

  /// Error domain from the iOS AppAuth SDk
  ///
  /// Only populated on iOS.
  final String? domain;

  /// Debug description for the error itself
  ///
  /// A debug description of the error from the platform's AppAuth SDK
  final String? errorDebugDescription;

  /// Debug description of the cause of the thrown error
  ///
  /// A debug description of the underlying cause of the error from the platform's AppAuth SDK
  final String? rootCauseDebugDescription;

  /// Whether or not this error is caused by user cancellation
  ///
  /// True if the user cancelled the authorization flow by closing the browser prematurely,
  /// False otherwise (for all actual errors).
  final bool userDidCancel;

  @override
  String toString() {
    return 'FlutterAppAuthPlatformErrorDetails(type: $type,\n code: $code,\n '
        'error: $error,\n errorDescription: $errorDescription,\n errorUri: $errorUri,\n domain $domain,\n'
        'rootCauseDebugDescription: $rootCauseDebugDescription,\n errorDebugDescription: $errorDebugDescription,\n userDidCancel: $userDidCancel\n)';
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
      userDidCancel: map['user_did_cancel']?.toLowerCase().trim() == 'true',
    );
  }
}

/// Thrown by methods that launch a browser session when the user cancels and closes the browser.
class FlutterAppAuthUserCancelledException extends PlatformException {

  final FlutterAppAuthPlatformErrorDetails platformErrorDetails;

  FlutterAppAuthUserCancelledException({
    required String code,
    String? message,
    dynamic legacyDetails,
    String? stacktrace,
    required this.platformErrorDetails,
  }) : super(
    code: code,
    message: message,
    details: legacyDetails,
    stacktrace: stacktrace,
  );

  @override
  String toString() {
    return 'FlutterAppAuthUserCancelledException{platformErrorDetails: $platformErrorDetails}';
  }
}

/// Exception thrown containing details of the error.
///
/// Details of the error occurred from the platform's AppAuth SDKs.
class FlutterAppAuthPlatformException extends PlatformException {

  final FlutterAppAuthPlatformErrorDetails platformErrorDetails;

  FlutterAppAuthPlatformException({
    required String code,
    String? message,
    dynamic legacyDetails,
    String? stacktrace,
    required this.platformErrorDetails,
  }) : super(
    code: code,
    message: message,
    details: legacyDetails,
    stacktrace: stacktrace,
  );
}
