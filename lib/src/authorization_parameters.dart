import 'mappable.dart';

mixin AuthorizationParameters on Mappable {
  /// Hint to the Authorization Server about the login identifier the End-User might use to log in
  String loginHint;

  /// list of ASCII string values that specifies whether the Authorization Server prompts the End-User for reauthentication and consent
  List<String> promptValues;

  Map<String, dynamic> toMap() {
    var map = super.toMap();
    map['loginHint'] = loginHint;
    map['promptValues'] = promptValues;
    return map;
  }
}
