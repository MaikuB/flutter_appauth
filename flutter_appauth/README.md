# Flutter AppAuth Plugin

[![pub package](https://img.shields.io/pub/v/flutter_appauth.svg)](https://pub.dartlang.org/packages/flutter_appauth)
[![Build Status](https://api.cirrus-ci.com/github/MaikuB/flutter_appauth.svg)](https://cirrus-ci.com/github/MaikuB/flutter_appauth/)

A Flutter bridge for AppAuth (https://appauth.io) used authenticating and authorizing users. Note that AppAuth also supports the PKCE extension that is required some providers so this plugin should work with them.

**IMPORTANT NOTES**:
- This plugin requires apps to be using AndroidX. The Flutter tooling supports creating apps with AndroidX support but requires passing the `androidx` flag. Details on AndroidX compatibility and migration can be found [here](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)
- If Chrome Custom Tabs are not working in your Android app, check to make sure that you have the latest version of this plugin, Android Studio, Gradle distribution and Android Gradle plugin for your app. There was previously a known [issue](https://issuetracker.google.com/issues/119183822) with the Android tooling with AndroidX that should now be resolved since Android Studio 3.4 has been released

## Tutorials from identity providers

* [Auth0](https://auth0.com/blog/get-started-with-flutter-authentication/)
* [FusionAuth](https://fusionauth.io/blog/2020/11/23/securing-flutter-oauth/)


## Getting Started

Please see the example that demonstrates how to sign into the IdentityServer4 demo site (https://demo.identityserver.io). It has also been tested with Azure B2C and Google Sign-in. It is suggested that developers check the documentation of the identity provider they are using to see what capabilities it supports e.g. how to logout, what values of the `prompt` parameter it supports etc. API docs can be found [here](https://pub.dartlang.org/documentation/flutter_appauth/latest/)


The first step is to create an instance of the plugin

```
FlutterAppAuth appAuth = FlutterAppAuth();
```

Afterwards, you'll reach a point where end-users need to be authorized and authenticated. A convenience method is provided that will perform an authorization request and automatically exchange the authorization code. This can be done in a few different ways, one of which is to use the OpenID Connect Discovery

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      discoveryUrl: '<discovery_url>',
                      scopes: ['openid','profile', 'email', 'offline_access', 'api'],
                    ),
                  );
```

Here the `<client_id>` and `<redirect_url>` should be replaced by the values registered with your identity provider. The `<discovery_url>` would be the URL for the discovery endpoint exposed by your provider that will return a document containing information about the OAuth 2.0 endpoints among other things. This URL is obtained by concatenating the issuer with the path `/.well-known/openid-configuration`. For example, the full URL for the IdentityServer4 demo site is `https://demo.identityserver.io/.well-known/openid-configuration`. As demonstrated in the above sample code, it's also possible specify the `scopes` being requested.

Rather than using the full discovery URL, the issuer could be used instead so that the process retrieving the discovery document is skipped

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      issuer: '<issuer>',
                      scopes: ['openid','profile', 'email', 'offline_access', 'api'],
                    ),
                  );
```

If you already know the authorization and token endpoints, which may be because discovery isn't supported, then these could be explicitly specified

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      serviceConfiguration: AuthorizationServiceConfiguration('<authorization_endpoint>', '<token_endpoint>'),
                      scopes: ['openid','profile', 'email', 'offline_access', 'api']
                    ),
                  );
```

Upon completing the request successfully, the method should return an object (the `result` variable in the above sample code is an instance of the `AuthorizationTokenResponse` class) that contain details that should be stored for future use e.g. access token, refresh token etc.

If you would prefer to not have the automatic code exchange to happen then can call the `authorize` method instead of the `authorizeAndExchangeCode` method. This will return an instance of the `AuthorizationResponse` class that will contain the code verifier that AppAuth generated (as part of implementing PKCE) when issuing the authorization request, the authorization code and additional parameters should they exist. Both of the code verifier and authorization code would need to be stored so they can then be reused to exchange the code later on e.g.

```dart
final TokenResponse result = await appAuth.token(TokenRequest('<client_id>', '<redirect_url>',
        authorizationCode: '<authorization_code>',
        discoveryUrl: '<discovery_url>',
        codeVerifier: '<code_verifier>',
        scopes: ['openid','profile', 'email', 'offline_access', 'api']));
```

### Refreshing tokens

Some providers may return a refresh token that could be used to refresh short-lived access tokens. A request to get a new access token before it expires could be made that would like similar to the following code

```dart
final TokenResponse result = await appAuth.token(TokenRequest('<client_id>', '<redirect_url>',
        discoveryUrl: '<discovery_url>',
        refreshToken: '<refresh_token>',
        scopes: ['openid','profile', 'email', 'offline_access', 'api']));
```

## Android setup

Go to the `build.gradle` file for your Android app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value

```
...
android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders = [
                'appAuthRedirectScheme': '<your_custom_scheme>'
        ]
    }
}
```

Please ensure that value of `<your_custom_scheme>` is all in lowercase as there've been reports from the community who had issues with redirects if there were any capital letters.

If your app is target API 30 or above (i.e. Android 11 or newer), make sure to add the following to your `AndroidManifest.xml` file a level underneath the `<manifest>` element


```xml
<queries>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.BROWSABLE" />
        <data android:scheme="https" />
    </intent>
    <intent>
        <action android:name="android.intent.action.VIEW" />
        <category android:name="android.intent.category.APP_BROWSER" />
        <data android:scheme="https" />
    </intent>
</queries>
```

## iOS setup

Go to the `Info.plist` for your iOS app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value


```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string><your_custom_scheme></string>
        </array>
    </dict>
</array>
```
