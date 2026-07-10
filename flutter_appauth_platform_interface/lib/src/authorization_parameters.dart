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

  /// OAuth 2.0 / OpenID Connect response types (e.g. `['code']`, `['id_token', 'token']`).
  ///
  /// Joined with a space when sent to the authorization endpoint as `response_type`.
  List<String>? responseTypes;
}
