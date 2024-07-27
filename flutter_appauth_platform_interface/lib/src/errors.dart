import 'package:flutter/services.dart';

/// The details of an error thrown from the underlying
/// platform AppAuth libraries.
class FlutterAppAuthPlatformErrorDetails {

  FlutterAppAuthPlatformErrorDetails({
    required this.type,
    required this.code,
    required this.error,
    required this.errorDescription,
    required this.errorUri,
    required this.rootCauseError,
    required this.userDidCancel,
  });

  /// On iOS: One of the domain values here: 
  ///         https://github.com/openid/AppAuth-iOS/blob/c89ed571ae140f8eb1142735e6e23d7bb8c34cb2/Sources/AppAuthCore/OIDError.m#L31
  /// On Android: One of the type codes here: 
  ///         https://github.com/openid/AppAuth-Android/blob/c6137b7db306d9c097c0d5763f3fb944cd0122d2/library/java/net/openid/appauth/AuthorizationException.java
  /// Recommend not using this field unless you really have to, see `error` field below.
  final String? type;

  /// On iOS: One of the enum values defined here depending on the error type
  ///         https://github.com/openid/AppAuth-iOS/blob/c89ed571ae140f8eb1142735e6e23d7bb8c34cb2/Sources/AppAuthCore/OIDError.h
  /// On Android: One of the codes defined here:
  ///          https://github.com/openid/AppAuth-Android/blob/c6137b7db306d9c097c0d5763f3fb944cd0122d2/library/java/net/openid/appauth/AuthorizationException.java#L158
  /// Recommend not using this field unless you really have to, see `error` field below.
  final String? code;

  /// For 400 errors from the Authorization server, this is error defined here: https://datatracker.ietf.org/doc/html/rfc6749#section-5.2
  /// e.g "invalid_grant"
  /// Otherwise a short error describing what happened.
  final String? error;

  /// Short, human readible error description.
  final String? errorDescription;

  /// The error Uri or domain from the underlying platform.
  final String? errorUri;

  /// The underlying raw error as a String debugging.
  final String? rootCauseError;

  /// True if the user cancelled the authorization flow by closing the browser prematurely
  /// False otherwise (for all actual errors).
  final bool userDidCancel;

  @override
  String toString() {
    return 'FlutterAppAuthPlatformErrorDetails(type: $type, code: $code, '
        'error: $error, errorDescription: $errorDescription, errorUri: $errorUri, '
        'rootCauseError: $rootCauseError, userDidCancel: $userDidCancel)';
  }

  static FlutterAppAuthPlatformErrorDetails fromMap(Map<String?, String?> map) {
    return FlutterAppAuthPlatformErrorDetails(
      type: map['type'],
      code: map['code'],
      error: map['error'],
      errorDescription: map['error_description'],
      errorUri: map['error_uri'],
      rootCauseError: map['root_cause_error'],
      userDidCancel: map['user_did_cancel']?.toLowerCase().trim() == 'true',
    );
  }
}

/// Exception that can be thrown by methods that launch a browser session
/// if the user cancels their authorization and closes the browser.
class FlutterAppAuthUserCancelledException extends PlatformException {

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

  final FlutterAppAuthPlatformErrorDetails platformErrorDetails;
}

/// Exception thrown containing details of the underlying error
/// that occurred within the iOS/Android libraries.
class FlutterAppAuthPlatformException extends PlatformException {

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

  final FlutterAppAuthPlatformErrorDetails platformErrorDetails;
}
