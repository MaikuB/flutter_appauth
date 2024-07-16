import 'package:flutter/services.dart';

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

  final String? type;
  final String? code;
  final String? error;
  final String? errorDescription;
  final String? errorUri;
  final String? rootCauseError;
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
