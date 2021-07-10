import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'authorization_request.dart';
import 'authorization_response.dart';
import 'authorization_token_request.dart';
import 'authorization_token_response.dart';
import 'end_session_request.dart';
import 'end_session_response.dart';
import 'method_channel_flutter_appauth.dart';
import 'token_request.dart';
import 'token_response.dart';

/// The platform interface that all implementations of flutter_appauth must implement.
abstract class FlutterAppAuthPlatform extends PlatformInterface {
  FlutterAppAuthPlatform() : super(token: _token);

  /// The default instance of [FlutterAppAuthPlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAppAuth].
  static FlutterAppAuthPlatform get instance => _instance;

  static FlutterAppAuthPlatform _instance = MethodChannelFlutterAppAuth();

  static final Object _token = Object();

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [FlutterAppAuthPlatform] when they register themselves.
  static set instance(FlutterAppAuthPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Convenience method for authorizing and then exchanges the authorization grant code.
  Future<AuthorizationTokenResponse?> authorizeAndExchangeCode(
      AuthorizationTokenRequest request) {
    throw UnimplementedError(
        'authorizeAndExchangeCode() has not been implemented');
  }

  /// Sends an authorization request.
  Future<AuthorizationResponse?> authorize(AuthorizationRequest request) {
    throw UnimplementedError('authorize() has not been implemented');
  }

  /// For exchanging tokens.
  Future<TokenResponse?> token(TokenRequest request) {
    throw UnimplementedError('token() has not been implemented');
  }

  Future<EndSessionResponse?> endSession(EndSessionRequest request) {
    throw UnimplementedError('endSession() has not been implemented');
  }
}
