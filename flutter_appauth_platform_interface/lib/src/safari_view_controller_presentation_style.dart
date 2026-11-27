/// Presentation style for `SFSafariViewController` on iOS.
///
/// This setting is only used when the `sfSafariViewController` external
/// user-agent is selected. Other external user agents and platforms ignore it.
enum SafariViewControllerPresentationStyle {
  /// Present as a form sheet. This is the default.
  formSheet,

  /// Present using the full-screen modal style.
  fullScreen,
}
