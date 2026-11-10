import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';

class FlutterAppAuth {
  const FlutterAppAuth();

  /// Convenience method for authorizing and then exchanges code
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) {
    return FlutterAppAuthPlatform.instance.authorizeAndExchangeCode(request);
  }

  /// Sends an authorization request.
  ///
  /// This is done by sending a request to the authorization server's
  /// [authorization endpoint](https://datatracker.ietf.org/doc/html/rfc6749#section-3.1).
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) {
    return FlutterAppAuthPlatform.instance.authorize(request);
  }

  /// For exchanging tokens.
  ///
  /// This is done by sending a request to the authorization server's
  /// [token endpoint](https://datatracker.ietf.org/doc/html/rfc6749#section-3.2).
  Future<TokenResponse> token(TokenRequest request) {
    return FlutterAppAuthPlatform.instance.token(request);
  }

  /// Performs an end session/logout request.
  ///
  /// This is done by sending a request to the authorization server's
  /// end session endpoint per the [RP-initiated logout spec](https://openid.net/specs/openid-connect-rpinitiated-1_0.html).
  Future<EndSessionResponse> endSession(EndSessionRequest request) {
    return FlutterAppAuthPlatform.instance.endSession(request);
  }

  /// Lists the browsers installed on an Android device that AppAuth could use.
  ///
  /// This is a development aid for finding the signature hashes of a browser
  /// to pin with [AndroidBrowser.custom]. See [InstalledAndroidBrowser]. Only
  /// implemented on Android.
  Future<List<InstalledAndroidBrowser>> getInstalledAndroidBrowsers() {
    return FlutterAppAuthPlatform.instance.getInstalledAndroidBrowsers();
  }
}
