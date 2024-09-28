// The external user-agent to use on iOS and macOS.
enum ExternalUserAgent {
  /// Uses the [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) APIs where possible.
  ///
  /// This is the default for macOS and iOS 12 and above. On iOS 11, it will
  /// use [SFAuthenticationSession](https://developer.apple.com/documentation/safariservices/sfauthenticationsession)
  /// instead.
  ///
  /// Behind the scenes, the plugin makes use of the default external user-agent
  /// provided by the AppAuth iOS SDK. This will use the best user-agent
  /// available on the device. Specifically, on iOS it will use [OIDExternalUserAgentIOS](https://openid.github.io/AppAuth-iOS/docs/latest/interface_o_i_d_external_user_agent_i_o_s.html)
  /// and on macOS it will use [OIDExternalUserAgentMac](https://openid.github.io/AppAuth-iOS/docs/latest/interface_o_i_d_external_user_agent_mac.html).
  ///
  /// Using this follows the best practices on using the appropriate native APIs
  /// based on the OS version.
  asWebAuthenticationSession,

  /// Indicates a preference in using an ephemeral sessions by using the [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
  /// APIs where possible.
  ///
  /// This is only applicable to macOS and iOS 12 and above. On these platforms,
  /// the session will not share browser data with user's normal browser session
  /// and does not keep the cache.
  ///
  /// Like [asWebAuthenticationSession], it fallback to use [SFAuthenticationSession](https://developer.apple.com/documentation/safariservices/sfauthenticationsession)
  /// on iOS 11 where there's no support for ephemeral sessions.
  ephemeralAsWebAuthenticationSession,

  /// Uses the [SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller)
  /// APIs.
  ///
  /// This does not share browser data with the user's normal browser session
  /// but keeps the cache.
  ///
  /// This is only applicable to iOS. On macOS, it will use the same behavior as
  /// [asWebAuthenticationSession].
  ///
  /// One reason for using this is when applications trigger an end session
  /// request but wants to avoid the prompt that would have appeared when the
  /// [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
  /// APIs are used. In this case, there's concern that the system-generated
  /// prompt would confuse the user as they are trying to sign out but the
  /// prompt states that it's taking the user through a sign-in flow.
  ///
  /// Note that as this does not follow the best practices on using the
  /// appropriate native APIs based on the OS version, developers should use
  /// this at their own discretion.
  sfSafariViewController
}
