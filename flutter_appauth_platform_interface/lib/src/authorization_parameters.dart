import 'external_agent_type.dart';

mixin AuthorizationParameters {
  /// Hint to the Authorization Server about the login identifier the End-User
  /// might use to log in.
  String? loginHint;

  /// List of ASCII string values that specifies whether the Authorization
  /// Server prompts the End-User for reauthentication and consent.
  List<String>? promptValues;

  /// Decides what type of external agent to use for the authorization flow.
  /// ASWebAuthenticationSession is the default for iOS 12 and above.
  /// EphemeralSession is not sharing browser data
  /// with the user's normal browser session but not keeping the cache
  /// SFSafariViewController is not sharing browser data
  /// with the user's normal browser session but keeping the cache.
  /// This property is only applicable to iOS versions 13 and above.
  /// ExternalAgentType? preferredExternalAgent;
  ExternalAgentType? preferredExternalAgent;

  String? responseMode;
}
