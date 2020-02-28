import 'dart:io';

class AuthorizationServiceConfiguration {
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String endSessionEndpoint;

  AuthorizationServiceConfiguration(
      this.authorizationEndpoint, this.tokenEndpoint, [this.endSessionEndpoint])
      : assert(tokenEndpoint != null && authorizationEndpoint != null,
            'Must specify both the authorization and token endpoints');

  Map<String, dynamic> toMap() {
    Map<String, dynamic> config = <String, dynamic>{
      'tokenEndpoint': tokenEndpoint,
      'authorizationEndpoint': authorizationEndpoint,
    };
    if (Platform.isIOS && endSessionEndpoint != null) {
      config['endSessionEndpoint'] = endSessionEndpoint;
    }
    return config;
  }
}
