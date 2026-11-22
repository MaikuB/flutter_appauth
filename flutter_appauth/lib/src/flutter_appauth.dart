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

  /// On Android, attempts to resume an authorization result that the native
  /// platform received while no Dart call is awaiting it. This can happen
  /// when the host Activity is recreated (e.g. by the OS reclaiming memory)
  /// while the authorization browser is in the foreground.
  /// Call this after the app has reinitialized to
  /// retrieve that result. Returns null if there is nothing pending.
  ///
  /// If the pending flow was started with [authorizeAndExchangeCode], the
  /// code exchange is performed as part of this call. In that case pass the
  /// same [clientSecret] and [allowInsecureConnections] values that were used
  /// for the original request, as the native side no longer has them after
  /// the Activity was recreated.
  ///
  /// Always returns null on other platforms.
  Future<AuthorizationResumeResponse?> resumePendingAuthorization({
    String? clientSecret,
    bool allowInsecureConnections = false,
  }) {
    return FlutterAppAuthPlatform.instance.resumePendingAuthorization(
      clientSecret: clientSecret,
      allowInsecureConnections: allowInsecureConnections,
    );
  }
}
