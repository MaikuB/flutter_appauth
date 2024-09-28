// Enum representing the type of external agent
// to use for the authorization flow.
enum ExternalAgentType {
  /// Uses ASWebAuthenticationSession, the default for iOS 12 and above.
  asWebAuthenticationSession,

  /// Uses an ephemeral session that does not share browser data with
  /// the user's normal browser session and does not keep the cache.
  ephemeralAsWebAuthenticationSession,

  /// Uses SFSafariViewController, which does not share browser data
  /// with the user's normal browser session but keeps the cache.
  ///
  /// This is only applicable to iOS, on macOS it will use the same behavior as
  /// ASWebAuthenticationSession.
  sfSafariViewController
}
