import 'package:flutter/services.dart';
import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:flutter_appauth_platform_interface/src/method_channel_flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      MethodChannel('crossingthestreams.io/flutter_appauth');
  final List<MethodCall> log = <MethodCall>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
    log.add(methodCall);
    return <Object, Object>{};
  });

  tearDown(() {
    log.clear();
  });

  final MethodChannelFlutterAppAuth flutterAppAuth =
      MethodChannelFlutterAppAuth();

  test('authorize', () async {
    await flutterAppAuth.authorize(AuthorizationRequest(
        'someClientId', 'someRedirectUrl',
        discoveryUrl: 'someDiscoveryUrl', loginHint: 'someLoginHint'));
    expect(
      log,
      <Matcher>[
        isMethodCall('authorize', arguments: <String, Object?>{
          'clientId': 'someClientId',
          'issuer': null,
          'redirectUrl': 'someRedirectUrl',
          'discoveryUrl': 'someDiscoveryUrl',
          'loginHint': 'someLoginHint',
          'scopes': null,
          'serviceConfiguration': null,
          'additionalParameters': null,
          'allowInsecureConnections': false,
          'externalUserAgent':
              ExternalUserAgent.asWebAuthenticationSession.index,
          'promptValues': null,
          'responseMode': null,
          'nonce': null,
        })
      ],
    );
  });

  test('authorizeAndExchangeCode', () async {
    await flutterAppAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(
        'someClientId', 'someRedirectUrl',
        discoveryUrl: 'someDiscoveryUrl',
        loginHint: 'someLoginHint',
        responseMode: 'fragment'));
    expect(
      log,
      <Matcher>[
        isMethodCall('authorizeAndExchangeCode', arguments: <String, Object?>{
          'clientId': 'someClientId',
          'issuer': null,
          'redirectUrl': 'someRedirectUrl',
          'discoveryUrl': 'someDiscoveryUrl',
          'loginHint': 'someLoginHint',
          'scopes': null,
          'serviceConfiguration': null,
          'additionalParameters': null,
          'allowInsecureConnections': false,
          'externalUserAgent':
              ExternalUserAgent.asWebAuthenticationSession.index,
          'promptValues': null,
          'clientSecret': null,
          'refreshToken': null,
          'authorizationCode': null,
          'grantType': 'authorization_code',
          'codeVerifier': null,
          'responseMode': 'fragment',
          'nonce': null,
        })
      ],
    );
  });

  group('token', () {
    test('cannot infer grant type', () async {
      expect(
          () async => await flutterAppAuth.token(TokenRequest(
              'someClientId', 'someRedirectUrl',
              discoveryUrl: 'someDiscoveryUrl')),
          throwsArgumentError);
    });
    test('infers refresh token grant type', () async {
      await flutterAppAuth.token(TokenRequest('someClientId', 'someRedirectUrl',
          discoveryUrl: 'someDiscoveryUrl', refreshToken: 'someRefreshToken'));
      expect(
        log,
        <Matcher>[
          isMethodCall('token', arguments: <String, Object?>{
            'clientId': 'someClientId',
            'issuer': null,
            'redirectUrl': 'someRedirectUrl',
            'discoveryUrl': 'someDiscoveryUrl',
            'scopes': null,
            'serviceConfiguration': null,
            'additionalParameters': null,
            'allowInsecureConnections': false,
            'clientSecret': null,
            'refreshToken': 'someRefreshToken',
            'authorizationCode': null,
            'grantType': 'refresh_token',
            'codeVerifier': null,
            'nonce': null,
          })
        ],
      );
    });

    test('infers authorization code grant type', () async {
      await flutterAppAuth.token(TokenRequest('someClientId', 'someRedirectUrl',
          discoveryUrl: 'someDiscoveryUrl',
          authorizationCode: 'someAuthorizationCode'));
      expect(
        log,
        <Matcher>[
          isMethodCall('token', arguments: <String, Object?>{
            'clientId': 'someClientId',
            'issuer': null,
            'redirectUrl': 'someRedirectUrl',
            'discoveryUrl': 'someDiscoveryUrl',
            'scopes': null,
            'serviceConfiguration': null,
            'additionalParameters': null,
            'allowInsecureConnections': false,
            'clientSecret': null,
            'refreshToken': null,
            'authorizationCode': 'someAuthorizationCode',
            'grantType': 'authorization_code',
            'codeVerifier': null,
            'nonce': null,
          })
        ],
      );
    });

    test('sends specified grant type', () async {
      await flutterAppAuth.token(TokenRequest('someClientId', 'someRedirectUrl',
          discoveryUrl: 'someDiscoveryUrl', grantType: 'someGrantType'));
      expect(
        log,
        <Matcher>[
          isMethodCall('token', arguments: <String, Object?>{
            'clientId': 'someClientId',
            'issuer': null,
            'redirectUrl': 'someRedirectUrl',
            'discoveryUrl': 'someDiscoveryUrl',
            'scopes': null,
            'serviceConfiguration': null,
            'additionalParameters': null,
            'allowInsecureConnections': false,
            'clientSecret': null,
            'refreshToken': null,
            'authorizationCode': null,
            'grantType': 'someGrantType',
            'codeVerifier': null,
            'nonce': null,
          })
        ],
      );
    });
  });

  test('endSession', () async {
    await flutterAppAuth.endSession(EndSessionRequest(
        idTokenHint: 'someIdToken',
        postLogoutRedirectUrl: 'somePostLogoutRedirectUrl',
        state: 'someState',
        discoveryUrl: 'someDiscoveryUrl'));
    expect(log, <Matcher>[
      isMethodCall('endSession', arguments: <String, Object?>{
        'idTokenHint': 'someIdToken',
        'postLogoutRedirectUrl': 'somePostLogoutRedirectUrl',
        'state': 'someState',
        'allowInsecureConnections': false,
        'additionalParameters': null,
        'issuer': null,
        'discoveryUrl': 'someDiscoveryUrl',
        'serviceConfiguration': null,
        'externalUserAgent': ExternalUserAgent.asWebAuthenticationSession.index,
      })
    ]);
  });

  group('resumePendingAuthorization', () {
    tearDown(() {
      // Restore the default handler used by the rest of the tests.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return <Object, Object>{};
      });
    });

    test('returns null when nothing is pending', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return null;
      });

      final AuthorizationResumeResponse? result =
          await flutterAppAuth.resumePendingAuthorization();

      expect(result, isNull);
      expect(log, <Matcher>[
        isMethodCall('resumePendingAuthorization', arguments: null)
      ]);
    });

    test('returns an AuthorizationResponse for a resumed authorize() flow',
        () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return <Object, Object?>{
          'authorizationCode': 'someAuthorizationCode',
          'codeVerifier': 'someCodeVerifier',
          'nonce': 'someNonce',
          'authorizationAdditionalParameters': <String, dynamic>{},
        };
      });

      final AuthorizationResumeResponse? result =
          await flutterAppAuth.resumePendingAuthorization();

      expect(result, isA<AuthorizationResumeResponseAuthorize>());
      final response = (result as AuthorizationResumeResponseAuthorize)
        .response;
      expect(response.authorizationCode,
          'someAuthorizationCode');
      expect(response.codeVerifier, 'someCodeVerifier');
      expect(response.nonce, 'someNonce');
      expect(response.authorizationAdditionalParameters, isNotNull);
    });

    test(
        'returns an AuthorizationTokenResponse for a resumed '
        'authorizeAndExchangeCode() flow', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        return <Object, Object?>{
          'accessToken': 'someAccessToken',
          'refreshToken': 'someRefreshToken',
          'accessTokenExpirationTime': 1784239200000,
          'idToken': 'someIdToken',
          'tokenType': 'bearer',
          'scopes': <String>['someScope'],
          'authorizationAdditionalParameters': <String, dynamic>{},
          'tokenAdditionalParameters': <String, dynamic>{},
        };
      });

      final AuthorizationResumeResponse? result =
          await flutterAppAuth.resumePendingAuthorization();

      expect(result, isA<AuthorizationResumeResponseToken>());
      final response = (result as AuthorizationResumeResponseToken).response;
      expect(
          response.accessToken, 'someAccessToken');
      expect(
          response.refreshToken, 'someRefreshToken');
      expect(response.accessTokenExpirationDateTime, DateTime(2026, 7, 17));
      expect(response.idToken, 'someIdToken');
      expect(response.tokenType, 'bearer');
      expect(response.scopes, ["someScope"]);
      expect(response.authorizationAdditionalParameters, isNotNull);
      expect(response.tokenAdditionalParameters, isNotNull);
    });
  });
}
