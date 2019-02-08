import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_appauth/flutter_appauth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  FlutterAppAuth _appAuth = FlutterAppAuth();
  String _refreshToken;
  String _accessToken;
  TextEditingController _accessTokenTextController = TextEditingController();
  TextEditingController _accessTokenExpirationTextController =
      TextEditingController();

  TextEditingController _idTokenTextController = TextEditingController();
  TextEditingController _refreshTokenTextController = TextEditingController();
  String _userInfo = '';

  // Google details
  String _clientId = 'native.code';
  String _redirectUrl = 'io.identityserver.demo:/oauthredirect';
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

  Future _refresh() async {
    var result = await _appAuth.token(TokenRequest(_clientId, _redirectUrl,
        refreshToken: _refreshToken,
        discoveryUrl: _discoveryUrl,
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
              RaisedButton(
                child: Text('Sign in'),
                onPressed: () async {
                  // use the discovery endpoint to find the configuration
                  var result = await _appAuth.authorizeAndExchangeToken(
                    AuthorizationTokenRequest(
                      _clientId,
                      _redirectUrl,
                      discoveryUrl: _discoveryUrl,
                      scopes: _scopes,
                    ),
                  );

                  // alternatively can explicitly specify the endpoints
                  // var result = await _appAuth.authorizeAndExchangeToken(
                  //   AuthorizationTokenRequest(
                  //     _clientId,
                  //     _redirectUrl,
                  //     serviceConfiguration: _serviceConfiguration,
                  //     scopes: _scopes,
                  //   ),
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

  void _processAuthTokenResponse(AuthorizationTokenResponse response) {
    setState(() {
      _accessToken = _accessTokenTextController.text = response.accessToken;
      _idTokenTextController.text = response.idToken;
      _refreshToken = _refreshTokenTextController.text = response.refreshToken;
      _accessTokenExpirationTextController.text =
          response.accessTokenExpirationDateTime?.toIso8601String();
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

  Future _testApi(TokenResponse response) async {
    var httpResponse = await http.get('https://demo.identityserver.io/api/test',
        headers: {'Authorization': 'Bearer $_accessToken'});
    setState(() {
      _userInfo = httpResponse.statusCode == 200 ? httpResponse.body : '';
    });
  }
}
