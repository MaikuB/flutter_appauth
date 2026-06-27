/// `dart:js_interop` bindings over the AppAuth-JS (`@openid/appauth`) bundle and
/// the helper layer in `js/entry.js`, exposed on the `AppAuth` global. Only the
/// subset used by `FlutterAppAuthWeb` is bound. Extension types (rather than
/// legacy `dart:html`/`package:js`) keep the plugin Wasm-compatible.
///
/// The lints below are disabled because the bindings use AppAuth-JS' own
/// snake_case parameter names and private JSON-shape types in constructors.
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: library_private_types_in_public_api
@JS()
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

/// Whether the bundle has loaded and the `AppAuth` global is available.
bool get isAppAuthLoaded => _appAuthGlobal != null;

@JS('AppAuth')
external JSObject? get _appAuthGlobal;

@JS('AppAuth.AuthorizationServiceConfiguration')
extension type AuthorizationServiceConfiguration._(JSObject _)
    implements JSObject {
  external factory AuthorizationServiceConfiguration(
    _ServiceConfigurationJson request,
  );

  // The authorization/token endpoints are consumed opaquely by the SDK; only
  // the end session endpoint is read back.
  external String? get endSessionEndpoint;
}

extension type _ServiceConfigurationJson._(JSObject _) implements JSObject {
  external factory _ServiceConfigurationJson({
    String authorization_endpoint,
    String token_endpoint,
    String? end_session_endpoint,
  });
}

/// An authorization request. The single-argument constructor applies the
/// AppAuth-JS defaults (Web Crypto plus PKCE).
@JS('AppAuth.AuthorizationRequest')
extension type AuthorizationRequest._(JSObject _) implements JSObject {
  external factory AuthorizationRequest(AuthorizationRequestJson request);

  /// SDK-managed values, including `code_verifier` once PKCE is set up.
  external JSObject? get internal;

  /// Extra authorization parameters (`nonce`, `prompt`, `login_hint`, ...).
  external JSObject? get extras;
}

extension type AuthorizationRequestJson._(JSObject _) implements JSObject {
  external factory AuthorizationRequestJson({
    String response_type,
    String client_id,
    String redirect_uri,
    String? scope,
    JSObject? extras,
  });
}

extension type AuthorizationResponse._(JSObject _) implements JSObject {
  external String get code;
}

/// An OAuth error, both from the notifier and the helper envelopes (the two
/// share this shape).
extension type OAuthError._(JSObject _) implements JSObject {
  external String get error;
  external String? get errorDescription;
  external String? get errorUri;
}

@JS('AppAuth.AuthorizationNotifier')
extension type AuthorizationNotifier._(JSObject _) implements JSObject {
  external factory AuthorizationNotifier();

  /// Registers a `(request, response, error) => void` completion listener.
  external void setAuthorizationListener(JSFunction listener);
}

/// The browser redirect handler. Created via [createRedirectRequestHandler],
/// which wires in a query-string-first response parser.
extension type RedirectRequestHandler._(JSObject _) implements JSObject {
  external void setAuthorizationNotifier(AuthorizationNotifier notifier);
  external void performAuthorizationRequest(
    AuthorizationServiceConfiguration configuration,
    AuthorizationRequest request,
  );

  /// Reads any authorization response from the current URL and dispatches it to
  /// the notifier.
  external JSPromise<JSObject?> completeAuthorizationRequestIfPossible();
}

@JS('AppAuth.TokenRequest')
extension type TokenRequest._(JSObject _) implements JSObject {
  external factory TokenRequest(TokenRequestJson request);
}

/// AppAuth-JS only serializes these fields plus `extras`, so `client_secret`,
/// `scope` and `code_verifier` are passed through `extras`.
extension type TokenRequestJson._(JSObject _) implements JSObject {
  external factory TokenRequestJson({
    String client_id,
    String redirect_uri,
    String grant_type,
    String? code,
    String? refresh_token,
    JSObject? extras,
  });
}

extension type TokenResponse._(JSObject _) implements JSObject {
  external String? get accessToken;
  external String? get refreshToken;
  external String? get scope;
  external String? get idToken;
  external String? get tokenType;

  /// Seconds until [accessToken] expires.
  external num? get expiresIn;

  /// Seconds since the epoch at which the token was issued.
  external num get issuedAt;
}

/// Envelope returned by [fetchServiceConfiguration].
extension type ConfigurationResult._(JSObject _) implements JSObject {
  external bool get ok;
  external AuthorizationServiceConfiguration? get configuration;
  external OAuthError? get error;
}

/// Envelope returned by [performTokenRequest].
extension type TokenRequestResult._(JSObject _) implements JSObject {
  external bool get ok;
  external TokenResponse? get response;
  external OAuthError? get error;
}

@JS('AppAuth.createRedirectRequestHandler')
external RedirectRequestHandler createRedirectRequestHandler();

/// Resolves the configuration from a [discoveryUrl] (fetched directly) or an
/// [issuer] (which appends the well-known discovery path).
@JS('AppAuth.fetchServiceConfiguration')
external JSPromise<ConfigurationResult> fetchServiceConfiguration(
  String? issuer,
  String? discoveryUrl,
);

@JS('AppAuth.performTokenRequest')
external JSPromise<TokenRequestResult> performTokenRequest(
  AuthorizationServiceConfiguration configuration,
  TokenRequest request,
);

extension JSObjectStringLookup on JSObject {
  /// Reads a string property, returning `null` when it is absent or not a
  /// string (rather than throwing a cast error).
  String? getStringProperty(String name) {
    final JSAny? value = getProperty<JSAny?>(name.toJS);
    return value.isDefinedAndNotNull && value!.typeofEquals('string')
        ? (value as JSString).toDart
        : null;
  }
}

AuthorizationServiceConfiguration createServiceConfiguration({
  required String authorizationEndpoint,
  required String tokenEndpoint,
  String? endSessionEndpoint,
}) => AuthorizationServiceConfiguration(
  _ServiceConfigurationJson(
    authorization_endpoint: authorizationEndpoint,
    token_endpoint: tokenEndpoint,
    end_session_endpoint: endSessionEndpoint,
  ),
);

/// Converts a Dart string map into a plain JS object, or `null` when empty.
JSObject? jsObjectFrom(Map<String, String> entries) {
  if (entries.isEmpty) {
    return null;
  }
  final JSObject object = JSObject();
  for (final MapEntry<String, String> entry in entries.entries) {
    object.setProperty(entry.key.toJS, entry.value.toJS);
  }
  return object;
}
