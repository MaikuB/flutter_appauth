mixin AuthorizationParameters {
  /// Hint to the Authorization Server about the login identifier the End-User might use to log in.
  String? loginHint;

  /// List of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent.
  List<String>? promptValues;

  /// Whether to use an ephemeral session that prevents cookies and other browser data being shared with the user's normal browser session.
  ///
  /// This property is only applicable to iOS versions 13 and above.  This setting is only validated when [defaultSystemBrowser] is set to false.
  bool? preferEphemeralSession;

  String? responseMode;

  /// Whether to open the default system browser outside the app.
  ///
  /// This property is only applicable to iOS. Set this to true if you want to use the cookies/context of the system main browser (such as SSO flows). This setting will nullify [preferEphemeralSession].
  bool? defaultSystemBrowser;
}
