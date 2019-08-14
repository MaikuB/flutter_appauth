import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isBusy = false;
  FlutterAppAuth _appAuth = FlutterAppAuth();
  String _codeVerifier;
  String _authorizationCode;
  String _refreshToken;
  String _accessToken;
  TextEditingController _authorizationCodeTextController =
      TextEditingController();
  TextEditingController _accessTokenTextController = TextEditingController();
  TextEditingController _accessTokenExpirationTextController =
      TextEditingController();

  TextEditingController _idTokenTextController = TextEditingController();
  TextEditingController _refreshTokenTextController = TextEditingController();
  String _userInfo = '';

  String _clientId = 'native.code';
  String _redirectUrl = 'io.identityserver.demo:/oauthredirect';
  String _issuer = 'https://demo.identityserver.io';
  String _discoveryUrl =
      'https://demo.identityserver.io/.well-known/openid-configuration';
  List<String> _scopes = [
    'openid',
    'profile',
    'email',
    'offline_access',
    'api'
  ];

  AuthorizationServiceConfiguration _serviceConfiguration =
      AuthorizationServiceConfiguration(
          'https://demo.identityserver.io/connect/authorize',
          'https://demo.identityserver.io/connect/token');

  @override
  void initState() {
    super.initState();
  }

  Future<void> _refresh() async {
    setBusyState();
    var result = await _appAuth.token(TokenRequest(_clientId, _redirectUrl,
        refreshToken: _refreshToken,
        discoveryUrl: _discoveryUrl,
        scopes: _scopes));
    _processTokenResponse(result);
    await _testApi(result);
  }

  Future<void> _exchangeCode() async {
    setBusyState();
    var result = await _appAuth.token(TokenRequest(_clientId, _redirectUrl,
        authorizationCode: _authorizationCode,
        discoveryUrl: _discoveryUrl,
        codeVerifier: _codeVerifier,
        scopes: _scopes));
    _processTokenResponse(result);
    await _testApi(result);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Visibility(
                visible: _isBusy,
                child: LinearProgressIndicator(),
              ),
              RaisedButton(
                child: Text('Sign in with no code exchange'),
                onPressed: () async {
                  setBusyState();
                  // use the discovery endpoint to find the configuration
                  var result = await _appAuth.authorize(
                    AuthorizationRequest(_clientId, _redirectUrl,
                        discoveryUrl: _discoveryUrl,
                        scopes: _scopes,
                        loginHint: 'bob'),
                  );

                  // or just use the issuer
                  // var result = await _appAuth.authorize(
                  //   AuthorizationRequest(
                  //     _clientId,
                  //     _redirectUrl,
                  //     issuer: _issuer,
                  //     scopes: _scopes,
                  //   ),
                  // );
                  if (result != null) {
                    _processAuthResponse(result);
                  }
                },
              ),
              RaisedButton(
                child: Text('Exchange code'),
                onPressed: _authorizationCode != null ? _exchangeCode : null,
              ),
              RaisedButton(
                child: Text('Sign in with auto code exchange'),
                onPressed: () async {
                  setBusyState();

                  // show that we can also explicitly specify the endpoints rather than getting from the details from the discovery document
                  var result = await _appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(_clientId, _redirectUrl,
                        serviceConfiguration: _serviceConfiguration,
                        scopes: _scopes),
                  );

                  // this code block demonstrates passing in values for the prompt parameter. in this case it prompts the user login even if they have already signed in. the list of supported values depends on the identity provider
                  // var result = await _appAuth.authorizeAndExchangeCode(
                  //   AuthorizationTokenRequest(_clientId, _redirectUrl,
                  //       serviceConfiguration: _serviceConfiguration,
                  //       scopes: _scopes,
                  //       promptValues: ['login']),
                  // );

                  if (result != null) {
                    _processAuthTokenResponse(result);
                    await _testApi(result);
                  }
                },
              ),
              RaisedButton(
                child: Text('Refresh token'),
                onPressed: _refreshToken != null ? _refresh : null,
              ),
              Text('authorization code'),
              TextField(
                controller: _authorizationCodeTextController,
              ),
              Text('access token'),
              TextField(
                controller: _accessTokenTextController,
              ),
              Text('access token expiration'),
              TextField(
                controller: _accessTokenExpirationTextController,
              ),
              Text('id token'),
              TextField(
                controller: _idTokenTextController,
              ),
              Text('refresh token'),
              TextField(
                controller: _refreshTokenTextController,
              ),
              Text('test api results'),
              Text(_userInfo),
            ],
          ),
        ),
      ),
    );
  }

  void setBusyState() {
    setState(() {
      _isBusy = true;
    });
  }

  void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _accessToken = _accessTokenTextController.text = response.accessToken;
      _idTokenTextController.text = response.idToken;
      _refreshToken = _refreshTokenTextController.text = response.refreshToken;
      _accessTokenExpirationTextController.text =
          response.accessTokenExpirationDateTime?.toIso8601String();
    });
  }

  void _processAuthResponse(AuthorizationResponse response) {
    setState(() {
      // save the code verifier as it must be used when exchanging the token
      _codeVerifier = response.codeVerifier;
      _authorizationCode =
          _authorizationCodeTextController.text = response.authorizationCode;
      _isBusy = false;
    });
  }

  void _processTokenResponse(TokenResponse response) {
    setState(() {
      _accessToken = _accessTokenTextController.text = response.accessToken;
      _idTokenTextController.text = response.idToken;
      _refreshToken = _refreshTokenTextController.text = response.refreshToken;
      _accessTokenExpirationTextController.text =
          response.accessTokenExpirationDateTime?.toIso8601String();
    });
  }

  Future<void> _testApi(TokenResponse response) async {
    var httpResponse = await http.get('https://demo.identityserver.io/api/test',
        headers: {'Authorization': 'Bearer $_accessToken'});
    setState(() {
      _userInfo = httpResponse.statusCode == 200 ? httpResponse.body : '';
      _isBusy = false;
    });
  }
}
