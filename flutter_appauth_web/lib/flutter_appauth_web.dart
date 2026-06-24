import 'dart:async';
import 'dart:js_interop';

import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart' as web;

import 'src/appauth_interop.dart' as js;
import 'src/redirect_url.dart';

typedef _Pending = ({
  js.AuthorizationResponse response,
  String? codeVerifier,
  String? nonce,
});

/// Web implementation of [FlutterAppAuthPlatform], wrapping the AppAuth-JS
/// (`@openid/appauth`) SDK that is bundled with this package.
///
/// The authorization code flow with PKCE uses a full-page redirect (popups are
/// not supported), so it spans two page loads: the call that starts sign in
/// navigates away and its future never completes, while the call made after the
/// redirect back — when the URL carries a `code` — resolves the result.
/// Applications should therefore call [authorizeAndExchangeCode] again on
/// startup when `Uri.base.queryParameters` contains `code`.
class FlutterAppAuthWeb extends FlutterAppAuthPlatform {
  static void registerWith(Registrar registrar) {
    final FlutterAppAuthWeb instance = FlutterAppAuthWeb();
    FlutterAppAuthPlatform.instance = instance;
    // Load eagerly so the SDK can complete a redirect on the first frame.
    unawaited(instance._ensureSdkLoaded());
  }

  // Flutter serves a plugin's declared assets under `assets/packages/<name>/`.
  static const String _bundleUrl =
      'assets/packages/flutter_appauth_web/assets/appauth.bundle.js';

  static Future<void>? _loadingFuture;

  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async {
    final js.AuthorizationServiceConfiguration configuration =
        await _resolveConfiguration(
          request.serviceConfiguration,
          request.issuer,
          request.discoveryUrl,
        );
    final _Pending? pending = await _completeOrStartAuthorization(
      configuration: configuration,
      clientId: request.clientId,
      redirectUrl: request.redirectUrl,
      scopes: request.scopes,
      nonce: request.nonce,
      loginHint: request.loginHint,
      promptValues: request.promptValues,
      responseMode: request.responseMode,
      additionalParameters: request.additionalParameters,
    );
    if (pending == null) {
      return Completer<AuthorizationResponse>().future;
    }
    return AuthorizationResponse(
      authorizationCode: pending.response.code,
      codeVerifier: pending.codeVerifier,
      nonce: pending.nonce,
    );
  }

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
    AuthorizationTokenRequest request,
  ) async {
    final js.AuthorizationServiceConfiguration configuration =
        await _resolveConfiguration(
          request.serviceConfiguration,
          request.issuer,
          request.discoveryUrl,
        );
    final _Pending? pending = await _completeOrStartAuthorization(
      configuration: configuration,
      clientId: request.clientId,
      redirectUrl: request.redirectUrl,
      scopes: request.scopes,
      nonce: request.nonce,
      loginHint: request.loginHint,
      promptValues: request.promptValues,
      responseMode: request.responseMode,
      additionalParameters: request.additionalParameters,
    );
    if (pending == null) {
      return Completer<AuthorizationTokenResponse>().future;
    }
    final js.TokenResponse token = await _performTokenRequest(
      configuration: configuration,
      clientId: request.clientId,
      redirectUrl: request.redirectUrl,
      clientSecret: request.clientSecret,
      grantType: GrantType.authorizationCode,
      authorizationCode: pending.response.code,
      codeVerifier: pending.codeVerifier,
      scopes: request.scopes,
      additionalParameters: request.additionalParameters,
    );
    return AuthorizationTokenResponse(
      token.accessToken,
      token.refreshToken,
      _expiration(token),
      token.idToken,
      token.tokenType,
      _scopes(token),
      null,
      null,
    );
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    final js.AuthorizationServiceConfiguration configuration =
        await _resolveConfiguration(
          request.serviceConfiguration,
          request.issuer,
          request.discoveryUrl,
        );
    final js.TokenResponse token = await _performTokenRequest(
      configuration: configuration,
      clientId: request.clientId,
      redirectUrl: request.redirectUrl,
      clientSecret: request.clientSecret,
      grantType: _inferGrantType(request),
      authorizationCode: request.authorizationCode,
      codeVerifier: request.codeVerifier,
      refreshToken: request.refreshToken,
      scopes: request.scopes,
      additionalParameters: request.additionalParameters,
    );
    return TokenResponse(
      token.accessToken,
      token.refreshToken,
      _expiration(token),
      token.idToken,
      token.tokenType,
      _scopes(token),
      null,
    );
  }

  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    final js.AuthorizationServiceConfiguration configuration =
        await _resolveConfiguration(
          request.serviceConfiguration,
          request.issuer,
          request.discoveryUrl,
        );
    final String? endSessionEndpoint = configuration.endSessionEndpoint;
    if (endSessionEndpoint == null) {
      throw _exception(
        'end_session_failed',
        'The discovered configuration has no end session endpoint.',
      );
    }
    // AppAuth-JS has no RP-initiated logout primitive, so redirect manually.
    final Uri endpoint = Uri.parse(endSessionEndpoint);
    final Uri uri = endpoint.replace(
      queryParameters: <String, String>{
        ...endpoint.queryParameters,
        if (request.idTokenHint != null) 'id_token_hint': request.idTokenHint!,
        if (request.postLogoutRedirectUrl != null)
          'post_logout_redirect_uri': request.postLogoutRedirectUrl!,
        if (request.state != null) 'state': request.state!,
        ...?request.additionalParameters,
      },
    );
    web.window.location.assign(uri.toString());
    return EndSessionResponse(request.state);
  }

  /// Resolves a pending authorization from the current URL, or starts a new one
  /// and returns `null` while the browser navigates away. Throws when the URL
  /// carries a response that cannot be completed, rather than looping into a
  /// fresh request.
  Future<_Pending?> _completeOrStartAuthorization({
    required js.AuthorizationServiceConfiguration configuration,
    required String clientId,
    required String redirectUrl,
    required List<String>? scopes,
    required String? nonce,
    required String? loginHint,
    required List<String>? promptValues,
    required String? responseMode,
    required Map<String, String>? additionalParameters,
  }) async {
    final js.RedirectRequestHandler handler = js.createRedirectRequestHandler();
    final js.AuthorizationNotifier notifier = js.AuthorizationNotifier();
    handler.setAuthorizationNotifier(notifier);

    final Completer<_Pending> completer = Completer<_Pending>();
    notifier.setAuthorizationListener(
      (
            js.AuthorizationRequest request,
            js.AuthorizationResponse? response,
            js.OAuthError? error,
          ) {
            if (completer.isCompleted) {
              return;
            }
            if (response != null) {
              completer.complete((
                response: response,
                codeVerifier: request.internal?.getStringProperty(
                  'code_verifier',
                ),
                nonce: request.extras?.getStringProperty('nonce'),
              ));
            } else if (error != null) {
              completer.completeError(
                _oauthException('authorize_failed', error),
              );
            }
          }
          .toJS,
    );

    // Completion reads the response from the URL; capture a storage failure so
    // it surfaces as the cause rather than as a generic "not handled".
    Object? completionError;
    try {
      await handler.completeAuthorizationRequestIfPossible().toDart;
    } catch (error) {
      completionError = error;
    }

    if (completer.isCompleted) {
      _cleanUpRedirectUrl();
      return completer.future;
    }

    if (hasAuthorizationResponse(Uri.base)) {
      _cleanUpRedirectUrl();
      throw _exception(
        'authorize_failed',
        completionError != null
            ? 'Failed to complete the authorization response: $completionError'
            : 'An authorization response was present but could not be '
                  'completed, usually a state mismatch or a pending request '
                  'missing from storage.',
      );
    }

    final js.AuthorizationRequest request = js.AuthorizationRequest(
      js.AuthorizationRequestJson(
        response_type: 'code',
        client_id: clientId,
        redirect_uri: redirectUrl,
        scope: scopes == null || scopes.isEmpty ? 'openid' : scopes.join(' '),
        extras: js.jsObjectFrom(<String, String>{
          if (nonce != null) 'nonce': nonce,
          if (loginHint != null) 'login_hint': loginHint,
          if (promptValues != null && promptValues.isNotEmpty)
            'prompt': promptValues.join(' '),
          if (responseMode != null) 'response_mode': responseMode,
          ...?additionalParameters,
        }),
      ),
    );
    handler.performAuthorizationRequest(configuration, request);
    return null;
  }

  // AppAuth-JS only serializes client_id/redirect_uri/grant_type/code/
  // refresh_token; client_secret, scope and the PKCE verifier must travel
  // through extras to reach the token endpoint.
  Future<js.TokenResponse> _performTokenRequest({
    required js.AuthorizationServiceConfiguration configuration,
    required String clientId,
    required String redirectUrl,
    required String grantType,
    String? clientSecret,
    String? authorizationCode,
    String? codeVerifier,
    String? refreshToken,
    List<String>? scopes,
    Map<String, String>? additionalParameters,
  }) async {
    final js.TokenRequest request = js.TokenRequest(
      js.TokenRequestJson(
        client_id: clientId,
        redirect_uri: redirectUrl,
        grant_type: grantType,
        code: authorizationCode,
        refresh_token: refreshToken,
        extras: js.jsObjectFrom(<String, String>{
          if (codeVerifier != null) 'code_verifier': codeVerifier,
          if (clientSecret != null) 'client_secret': clientSecret,
          if (scopes != null && scopes.isNotEmpty) 'scope': scopes.join(' '),
          ...?additionalParameters,
        }),
      ),
    );
    final js.TokenRequestResult result = await js
        .performTokenRequest(configuration, request)
        .toDart;
    if (!result.ok) {
      throw _oauthException('token_failed', result.error);
    }
    return result.response!;
  }

  Future<js.AuthorizationServiceConfiguration> _resolveConfiguration(
    AuthorizationServiceConfiguration? serviceConfiguration,
    String? issuer,
    String? discoveryUrl,
  ) async {
    await _ensureSdkLoaded();
    if (serviceConfiguration != null) {
      return js.createServiceConfiguration(
        authorizationEndpoint: serviceConfiguration.authorizationEndpoint,
        tokenEndpoint: serviceConfiguration.tokenEndpoint,
        endSessionEndpoint: serviceConfiguration.endSessionEndpoint,
      );
    }
    if (issuer == null && discoveryUrl == null) {
      throw _exception(
        'configuration_failed',
        'Either the issuer, discovery URL or service configuration must be '
            'provided.',
      );
    }
    final js.ConfigurationResult result = await js
        .fetchServiceConfiguration(issuer, discoveryUrl)
        .toDart;
    if (!result.ok) {
      throw _oauthException('discovery_failed', result.error);
    }
    return result.configuration!;
  }

  Future<void> _ensureSdkLoaded() {
    // Clear the cache on failure so a transient first-load error can retry.
    return _loadingFuture ??= _injectBundle().onError((Object error, _) {
      _loadingFuture = null;
      throw error;
    });
  }

  Future<void> _injectBundle() async {
    if (js.isAppAuthLoaded) {
      return;
    }
    // A leftover script while the global is still absent is a finished, failed
    // load (a live one is serialized through `_loadingFuture`); its events will
    // never fire again, so replace it rather than awaiting it forever.
    web.document.querySelector('script[src="$_bundleUrl"]')?.remove();
    final web.HTMLScriptElement script = web.HTMLScriptElement()
      ..type = 'text/javascript'
      ..src = _bundleUrl
      ..async = true;
    web.document.head!.appendChild(script);
    await _awaitScriptLoad(script);
    if (!js.isAppAuthLoaded) {
      throw _exception(
        'sdk_load_failed',
        'The AppAuth-JS bundle loaded without exposing its global.',
      );
    }
  }

  Future<void> _awaitScriptLoad(web.HTMLScriptElement script) {
    final Completer<void> completer = Completer<void>();
    script
      ..addEventListener(
        'load',
        (web.Event _) {
          if (!completer.isCompleted) {
            completer.complete();
          }
        }.toJS,
      )
      ..addEventListener(
        'error',
        (web.Event _) {
          if (!completer.isCompleted) {
            completer.completeError(
              _exception('sdk_load_failed', 'Failed to load $_bundleUrl.'),
            );
          }
        }.toJS,
      );
    return completer.future;
  }

  void _cleanUpRedirectUrl() {
    web.window.history.replaceState(
      null,
      '',
      redirectUrlWithoutResponse(Uri.base),
    );
  }

  static DateTime? _expiration(js.TokenResponse response) {
    final num? expiresIn = response.expiresIn;
    return expiresIn == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(
            ((response.issuedAt + expiresIn) * 1000).round(),
          );
  }

  static List<String>? _scopes(js.TokenResponse response) {
    final String? scope = response.scope;
    return scope == null || scope.isEmpty ? null : scope.split(' ');
  }

  // Mirrors the inference in the platform interface's method-channel mapper,
  // including the failure when no grant type is given and none can be inferred.
  static String _inferGrantType(TokenRequest request) {
    if (request.grantType != null) {
      return request.grantType!;
    }
    if (request.refreshToken != null) {
      return GrantType.refreshToken;
    }
    if (request.authorizationCode != null) {
      return GrantType.authorizationCode;
    }
    throw ArgumentError.value(
      null,
      'grantType',
      'Grant type not specified and cannot be inferred',
    );
  }

  static FlutterAppAuthPlatformException _oauthException(
    String code,
    js.OAuthError? error,
  ) {
    return FlutterAppAuthPlatformException(
      code: code,
      message: error?.errorDescription ?? error?.error ?? code,
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
        error: error?.error ?? code,
        errorDescription: error?.errorDescription,
        errorUri: error?.errorUri,
      ),
    );
  }

  static FlutterAppAuthPlatformException _exception(
    String code,
    String message,
  ) {
    return FlutterAppAuthPlatformException(
      code: code,
      message: message,
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
        error: code,
        errorDescription: message,
      ),
    );
  }
}
