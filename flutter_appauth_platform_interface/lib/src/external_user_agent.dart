// The external user-agent to use on iOS and macOS.
enum ExternalUserAgent {
  /// Uses [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) where possible.
  ///
  /// This is the default for macOS and iOS 12 and above. On iOS 11, it will
  /// use [SFAuthenticationSession](https://developer.apple.com/documentation/safariservices/sfauthenticationsession)
  /// instead.
  ///
  /// Behind the scenes, the plugin makes use of the default external user-agent
  /// provided by the AppAuth iOS SDK. This will use the best user-agent
  /// available on the device. Specifically, on iOS it will use [OIDExternalUserAgentIOS](https://openid.github.io/AppAuth-iOS/docs/latest/interface_o_i_d_external_user_agent_i_o_s.html)
  /// and on macOS it will use [OIDExternalUserAgentMac](https://openid.github.io/AppAuth-iOS/docs/latest/interface_o_i_d_external_user_agent_mac.html).
  asWebAuthenticationSession,

  /// Indicates a preference in using ephemeral ASWebAuthenticationSession.
  ///
  /// This is only applicable to macOS and iOS 12 and above. On these platforms,
  /// the session will not share browser data with user's normal browser session
  /// and does not keep the cache.
  ///
  /// On iOS 11, it will have the same behavior as [asWebAuthenticationSession].
  ephemeralAsWebAuthenticationSession,

  /// Uses [SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller), which does not share browser data
  /// with the user's normal browser session but keeps the cache.
  ///
  /// This is only applicable to iOS. On macOS, it will use the same behavior as
  /// [asWebAuthenticationSession].
  sfSafariViewController
}
