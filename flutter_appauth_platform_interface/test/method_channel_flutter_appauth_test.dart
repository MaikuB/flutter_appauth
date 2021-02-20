import 'package:flutter/services.dart';
import 'package:flutter_appauth_platform_interface/src/method_channel_flutter_appauth.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_appauth_platform_interface/flutter_appauth_platform_interface.dart';
import 'package:mockito/mockito.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel channel =
      MethodChannel('crossingthestreams.io/flutter_appauth');
  final List<MethodCall> log = <MethodCall>[];
  channel.setMockMethodCallHandler((MethodCall methodCall) async {
    log.add(methodCall);
  });

  tearDown(() {
    log.clear();
  });

  MethodChannelFlutterAppAuth flutterAppAuth = MethodChannelFlutterAppAuth();
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
          'preferEphemeralSession': false,
          'promptValues': null,
        })
      ],
    );
  });

  test('authorizeAndExchangeCode', () async {
    await flutterAppAuth.authorizeAndExchangeCode(AuthorizationTokenRequest(
        'someClientId', 'someRedirectUrl',
        discoveryUrl: 'someDiscoveryUrl', loginHint: 'someLoginHint'));
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
          'preferEphemeralSession': false,
          'promptValues': null,
          'clientSecret': null,
          'refreshToken': null,
          'authorizationCode': null,
          'grantType': 'authorization_code',
          'codeVerifier': null
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
            'codeVerifier': null
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
            'codeVerifier': null
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
            'codeVerifier': null
          })
        ],
      );
    });
  });
}

class FlutterAppAuthPlatformMock extends Mock
    with MockPlatformInterfaceMixin
    implements FlutterAppAuthPlatform {}

class ImplementsFlutterAppAuthPlatform extends Mock
    implements FlutterAppAuthPlatform {}

class ExtendsFlutterAppAuthPlatform extends FlutterAppAuthPlatform {}
