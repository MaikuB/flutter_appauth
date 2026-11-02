import 'external_user_agent.dart';
import 'safari_view_controller_presentation_style.dart';

mixin AuthorizationParameters {
  /// Hint to the Authorization Server about the login identifier the End-User
  /// might use to log in.
  String? loginHint;

  /// List of ASCII string values that specifies whether the Authorization
  /// Server prompts the End-User for reauthentication and consent.
  List<String>? promptValues;

  /// Specifies the external user-agent to use.
  ExternalUserAgent? externalUserAgent;

  /// Specifies the presentation style when
  /// [ExternalUserAgent.sfSafariViewController] is selected.
  ///
  /// This is only applicable to iOS. The default is
  /// [SafariViewControllerPresentationStyle.formSheet].
  SafariViewControllerPresentationStyle? safariViewControllerPresentationStyle;

  /// Specifies the response mode to use.
  String? responseMode;
}
