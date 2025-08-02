import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

class FlutterAppAuthWeb extends FlutterAppAuthPlatform {
  static String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  static void registerWith(Registrar registrar) {
    _checkForOAuthCallbackOnInit();
    FlutterAppAuthPlatform.instance = FlutterAppAuthWeb._();
  }

  static AuthorizationResponse? _pendingAuthResponse;
  static Completer<AuthorizationTokenResponse>? _pendingTokenCompleter;
  static bool _hasCheckedCallback = false;
  static Map<String, dynamic>? _pendingRequest;

  FlutterAppAuthWeb._();

  FlutterAppAuthWeb() {
    _checkForOAuthCallbackOnInit();
  }

  static void _checkForOAuthCallbackOnInit() {
    if (_hasCheckedCallback) return;
    _hasCheckedCallback = true;
    final uri = Uri.parse(web.window.location.href);
    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];

    if (code != null) {
      final storedState = web.window.sessionStorage['appauth_state'];
      final codeVerifier = web.window.sessionStorage['appauth_code_verifier'];
      final nonce = web.window.sessionStorage['appauth_nonce'];

      if (returnedState == storedState) {
        _pendingAuthResponse = AuthorizationResponse(
          authorizationCode: code,
          codeVerifier: codeVerifier,
          nonce: nonce,
        );

        final storedRequest = web.window.sessionStorage['appauth_request'];
        if (storedRequest != null) {
          try {
            _pendingRequest =
            json.decode(storedRequest) as Map<String, dynamic>;
            web.window.sessionStorage.removeItem('appauth_request');
          } catch (e) {
            // Ignore parsing errors
          }
        }
      }
    }
  }

  String _generateRandomString(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789-._~';
    final random = Random.secure();
    return List.generate(length, (_) => chars[random.nextInt(chars.length)])
        .join();
  }

  String _generateCodeChallenge(String codeVerifier) {
    return generateCodeChallenge(codeVerifier);
  }

  Future<AuthorizationTokenResponse> _completeTokenExchange(
      AuthorizationTokenRequest request,
      AuthorizationResponse authResponse,) async {
    final tokenResponse = await token(
      TokenRequest(
        request.clientId,
        request.redirectUrl,
        issuer: request.issuer,
        discoveryUrl: request.discoveryUrl,
        serviceConfiguration: request.serviceConfiguration,
        scopes: request.scopes,
        additionalParameters: request.additionalParameters,
        allowInsecureConnections: request.allowInsecureConnections ?? false,
        authorizationCode: authResponse.authorizationCode,
        codeVerifier: authResponse.codeVerifier,
        grantType: GrantType.authorizationCode,
      ),
    );

    final finalResponse = AuthorizationTokenResponse(
      tokenResponse.accessToken,
      tokenResponse.refreshToken,
      tokenResponse.accessTokenExpirationDateTime,
      tokenResponse.idToken,
      tokenResponse.tokenType,
      tokenResponse.scopes,
      authResponse.authorizationAdditionalParameters,
      tokenResponse.tokenAdditionalParameters,
    );

    _pendingAuthResponse = null;
    web.window.sessionStorage.removeItem('appauth_state');
    web.window.sessionStorage.removeItem('appauth_code_verifier');
    web.window.sessionStorage.removeItem('appauth_nonce');

    final currentUri = Uri.parse(web.window.location.href);
    final cleanedUri = currentUri.replace(queryParameters: {});
    web.window.history.replaceState(null, '', cleanedUri.toString());

    return finalResponse;
  }

  @override
  Future<AuthorizationResponse> authorize(AuthorizationRequest request) async {
    if (_pendingAuthResponse != null) {
      final response = _pendingAuthResponse!;
      _pendingAuthResponse = null;
      return response;
    }

    final codeVerifier = _generateRandomString(128);
    final codeChallenge = _generateCodeChallenge(codeVerifier);

    final state = _generateRandomString(32);

    web.window.sessionStorage['appauth_code_verifier'] = codeVerifier;
    web.window.sessionStorage['appauth_state'] = state;
    if (request.nonce != null) {
      web.window.sessionStorage['appauth_nonce'] = request.nonce!;
    }

    final authorizationEndpoint =
        request.serviceConfiguration!.authorizationEndpoint;
    final params = <String, String>{
      'client_id': request.clientId,
      'redirect_uri': request.redirectUrl,
      'response_type': 'code',
      'scope': request.scopes?.join(' ') ?? 'openid profile',
      'state': state,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    if (request.nonce != null) {
      params['nonce'] = request.nonce!;
    }

    if (request.loginHint != null) {
      params['login_hint'] = request.loginHint!;
    }

    if (request.promptValues != null) {
      params['prompt'] = request.promptValues!.join(' ');
    }

    if (request.responseMode != null) {
      params['response_mode'] = request.responseMode!;
    }

    request.additionalParameters?.forEach((key, value) {
      params[key] = value;
    });

    final authUri = Uri.parse(authorizationEndpoint).replace(
      queryParameters: params,
    );

    web.window.location.href = authUri.toString();

    return Completer<AuthorizationResponse>().future;
  }

  @override
  Future<TokenResponse> token(TokenRequest request) async {
    final tokenEndpoint = request.serviceConfiguration!.tokenEndpoint;

    final body = <String, String>{
      'client_id': request.clientId,
      'redirect_uri': request.redirectUrl,
      'grant_type': request.grantType!,
    };

    if (request.authorizationCode != null) {
      body['code'] = request.authorizationCode!;
    }

    if (request.codeVerifier != null) {
      body['code_verifier'] = request.codeVerifier!;
    }

    if (request.refreshToken != null) {
      body['refresh_token'] = request.refreshToken!;
    }

    if (request.scopes != null) {
      body['scope'] = request.scopes!.join(' ');
    }

    request.additionalParameters?.forEach((key, value) {
      body[key] = value;
    });

    final bodyString = body.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    final response = await http.post(
      Uri.parse(tokenEndpoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: bodyString,
    );

    if (response.statusCode != 200) {
      throw FlutterAppAuthPlatformException(
        code: 'token_failed',
        message: 'Token request failed with status ${response.statusCode}',
        platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
          error: 'token_request_failed',
          errorDescription:
          'Token request failed with status ${response.statusCode}',
        ),
      );
    }

    final responseData = json.decode(response.body) as Map<String, dynamic>;

    return TokenResponse(
      responseData['access_token'] as String?,
      responseData['refresh_token'] as String?,
      responseData['access_token'] != null
          ? DateTime.now().add(
        Duration(seconds: responseData['expires_in'] as int? ?? 3600),
      )
          : null,
      responseData['id_token'] as String?,
      responseData['token_type'] as String?,
      responseData['scope']?.toString().split(' '),
      {
        for (final entry in responseData.entries)
          if (![
            'access_token',
            'refresh_token',
            'expires_in',
            'id_token',
            'token_type',
            'scope'
          ].contains(entry.key))
            entry.key: entry.value.toString()
      },
    );
  }

  @override
  Future<AuthorizationTokenResponse> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) async {
    if (_pendingAuthResponse != null && _pendingRequest != null &&
        _pendingRequest!['isAuthorizeAndExchangeCode'] == 'true') {
      AuthorizationServiceConfiguration? serviceConfig;
      if (_pendingRequest!['serviceConfiguration'] != null) {
        final configData = _pendingRequest!['serviceConfiguration'] as Map<
            String,
            dynamic>;
        serviceConfig = AuthorizationServiceConfiguration(
          authorizationEndpoint: configData['authorizationEndpoint'] as String,
          tokenEndpoint: configData['tokenEndpoint'] as String,
          endSessionEndpoint: configData['endSessionEndpoint'] as String?,
        );
      }

      final storedRequest = AuthorizationTokenRequest(
        _pendingRequest!['clientId'] as String,
        _pendingRequest!['redirectUrl'] as String,
        issuer: _pendingRequest!['issuer'] as String?,
        discoveryUrl: _pendingRequest!['discoveryUrl'] as String?,
        scopes: (_pendingRequest!['scopes'] as List<dynamic>?)?.cast<String>(),
        additionalParameters: (_pendingRequest!['additionalParameters'] as Map<
            String,
            dynamic>?)?.cast<String, String>(),
        allowInsecureConnections: _pendingRequest!['allowInsecureConnections'] as bool? ??
            false,
        serviceConfiguration: serviceConfig ?? request.serviceConfiguration,
      );
      _pendingRequest = null;
      return _completeTokenExchange(storedRequest, _pendingAuthResponse!);
    }

    final requestData = <String, dynamic>{
      'clientId': request.clientId,
      'redirectUrl': request.redirectUrl,
      'issuer': request.issuer,
      'discoveryUrl': request.discoveryUrl,
      'scopes': request.scopes,
      'additionalParameters': request.additionalParameters,
      'allowInsecureConnections': request.allowInsecureConnections,
      'isAuthorizeAndExchangeCode': 'true',
    };

    if (request.serviceConfiguration != null) {
      requestData['serviceConfiguration'] = {
        'authorizationEndpoint': request.serviceConfiguration!
            .authorizationEndpoint,
        'tokenEndpoint': request.serviceConfiguration!.tokenEndpoint,
        'endSessionEndpoint': request.serviceConfiguration!.endSessionEndpoint,
      };
    }

    web.window.sessionStorage['appauth_request'] = json.encode(requestData);

    await authorize(
      AuthorizationRequest(
        request.clientId,
        request.redirectUrl,
        issuer: request.issuer,
        discoveryUrl: request.discoveryUrl,
        serviceConfiguration: request.serviceConfiguration,
        loginHint: request.loginHint,
        scopes: request.scopes,
        additionalParameters: request.additionalParameters,
        promptValues: request.promptValues,
        allowInsecureConnections: request.allowInsecureConnections ?? false,
        nonce: request.nonce,
        responseMode: request.responseMode,
      ),
    );

    throw FlutterAppAuthPlatformException(
      code: 'authorization_in_progress',
      message: 'Authorization is in progress. The page will redirect.',
      platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
        error: 'redirect_in_progress',
        errorDescription: 'The authorization flow requires a page redirect.',
      ),
    );
  }

  @override
  Future<EndSessionResponse> endSession(EndSessionRequest request) async {
    final endSessionEndpoint = request.serviceConfiguration!.endSessionEndpoint;

    if (endSessionEndpoint == null) {
      throw FlutterAppAuthPlatformException(
        code: 'end_session_failed',
        message: 'End session endpoint not configured',
        platformErrorDetails: FlutterAppAuthPlatformErrorDetails(
          error: 'missing_end_session_endpoint',
          errorDescription: 'End session endpoint not configured',
        ),
      );
    }

    final params = <String, String>{};

    if (request.idTokenHint != null) {
      params['id_token_hint'] = request.idTokenHint!;
    }

    if (request.postLogoutRedirectUrl != null) {
      params['post_logout_redirect_uri'] = request.postLogoutRedirectUrl!;
    }

    if (request.state != null) {
      params['state'] = request.state!;
    }

    request.additionalParameters?.forEach((key, value) {
      params[key] = value;
    });

    final uri = Uri.parse(endSessionEndpoint).replace(
      queryParameters: params,
    );

    web.window.location.href = uri.toString();

    return EndSessionResponse(request.state);
  }
}
