mixin AuthorizationParameters {
  /// Hint to the Authorization Server about the login identifier the End-User might use to log in.
  String? loginHint;

  /// List of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent.
  List<String>? promptValues;

  /// Whether to use an ephemeral session that prevents cookies and other browser data being shared with the user's normal browser session.
  ///
  /// This property is only applicable to iOS versions 13 and above.
  bool? preferEphemeralSession;

  String? responseMode;

  // Authorization protocols provide a custom state parameter that allows you to restore the previous state of your application. The custom state parameter
  // preserves some state objects set by the client in the auhtorization request and makes it available to the client in the response
  // if the state parameter is not set it will be handled natively by generating a random string

  String? state;
}
