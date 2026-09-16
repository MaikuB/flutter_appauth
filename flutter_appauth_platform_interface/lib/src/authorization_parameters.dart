import 'android_browser.dart';
import 'external_user_agent.dart';

mixin AuthorizationParameters {
  /// Hint to the Authorization Server about the login identifier the End-User
  /// might use to log in.
  String? loginHint;

  /// List of ASCII string values that specifies whether the Authorization
  /// Server prompts the End-User for reauthentication and consent.
  List<String>? promptValues;

  /// Specifies the external user-agent to use.
  ExternalUserAgent? externalUserAgent;

  /// Specifies the response mode to use.
  String? responseMode;

  /// Restricts which Android browsers (or Custom Tab implementations) are
  /// allowed to handle the request.
  ///
  /// This is only applicable to Android. A `null` or empty list means any
  /// installed browser may be used, which is the existing behaviour. If none
  /// of the installed browsers match, the request fails the same way it
  /// would if no browser were installed at all.
  List<AndroidBrowser>? androidAllowedBrowsers;
}
