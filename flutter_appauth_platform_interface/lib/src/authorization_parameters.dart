import 'mappable.dart';

mixin AuthorizationParameters on Mappable {
  /// Hint to the Authorization Server about the login identifier the End-User might use to log in.
  String loginHint;

  /// List of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent.
  List<String> promptValues;

  /// Whether to use an ephemeral session that prevents cookies and other browser data being shared with the user's normal browser session.
  ///
  /// Only applies to iOS versions 13 and above.
  bool preferEphemeralSession;

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = super.toMap();
    map['loginHint'] = loginHint;
    map['promptValues'] = promptValues;
    map['preferEphemeralSession'] = preferEphemeralSession;
    return map;
  }
}
