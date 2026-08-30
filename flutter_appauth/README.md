# Flutter AppAuth Plugin

[![pub package](https://img.shields.io/pub/v/flutter_appauth.svg)](https://pub.dartlang.org/packages/flutter_appauth)
[![Build Status](https://api.cirrus-ci.com/github/MaikuB/flutter_appauth.svg)](https://cirrus-ci.com/github/MaikuB/flutter_appauth/)

- [Introduction](#introduction)
- [Tutorials from identity providers](#tutorials-from-identity-providers)
- [Getting Started](#getting-started)
  - [Detecting user cancellation](#detecting-user-cancellation)
  - [Refreshing tokens](#refreshing-tokens)
  - [End session](#end-session)
  - [Handling errors](#handling-errors)
  - [Ephemeral Sessions (iOS and macOS only)](#ephemeral-sessions-ios-and-macos-only)
- [Android setup](#android-setup)
- [iOS/macOS setup](#iosmacos-setup)
  - [Using https redirect URIs on iOS 17.4+](#using-https-redirect-uris-on-ios-174)
- [API docs](#api-docs)
- [FAQs](#faqs)


## Introduction 
A Flutter bridge for AppAuth (https://appauth.io) used authenticating and authorizing users. Note that AppAuth also supports the PKCE extension that is required some providers so this plugin should work with them.

**IMPORTANT NOTES**:
- This plugin requires apps to be using AndroidX. The Flutter tooling supports creating apps with AndroidX support but requires passing the `androidx` flag. Details on AndroidX compatibility and migration can be found [here](https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility)
- If Chrome Custom Tabs are not working in your Android app, check to make sure that you have the latest version of this plugin, Android Studio, Gradle distribution and Android Gradle plugin for your app. There was previously a known [issue](https://issuetracker.google.com/issues/119183822) with the Android tooling with AndroidX that should now be resolved since Android Studio 3.4 has been released

## Tutorials from identity providers

The following are tutorials from identity providers that reference using this plugin. If the identity provider you're using isn't in this list, it doesn't mean that plugin doesn't work with it. It only means that these are some of the identity providers that have tutorials that specify that developers can use this plugin. Generally, if your identity provider supports OAuth 2.0 and follows the industry standards and specifications then the plugin can be expected to work. Developers should also note that the following links are managed by external parties. If you choose to open these links, do so at your own risk and be aware that it's possible the content may be out of date

* [Asgardeo](https://wso2.com/asgardeo/docs/tutorials/auth-users-into-flutter-apps/)
* [FusionAuth](https://fusionauth.io/docs/quickstarts/quickstart-flutter-native#setting-up-appauth)


## Getting Started

Please see the example that demonstrates how to sign into the demo IdentityServer instance (https://demo.duendesoftware.com). It has also been tested with Azure B2C, Auth0, FusionAuth and Google Sign-in. Developers should check the documentation of the identity provider they are using to see what capabilities it supports (e.g. how to logout, what values of the `prompt` parameter it supports etc) and how to configure/register their application with the identity provider. Understanding [OAuth 2.0](https://datatracker.ietf.org/doc/html/rfc6749) is also essential, especially when it comes to [best practices for native mobile apps](https://datatracker.ietf.org/doc/html/rfc8252).

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

Here the `<client_id>` and `<redirect_url>` should be replaced by the values registered with your identity provider. The `<discovery_url>` would be the URL for the discovery endpoint exposed by your provider that will return a document containing information about the OAuth 2.0 endpoints among other things. This URL is obtained by concatenating the issuer with the path `/.well-known/openid-configuration`. For example, the full URL for the IdentityServer instance is `https://demo.duendesoftware.com/.well-known/openid-configuration`. As demonstrated in the above sample code, it's also possible specify the `scopes` being requested.

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

In the event that discovery isn't supported or that you already know the endpoints for your server, they could be explicitly specified

```dart
final AuthorizationTokenResponse result = await appAuth.authorizeAndExchangeCode(
                    AuthorizationTokenRequest(
                      '<client_id>',
                      '<redirect_url>',
                      serviceConfiguration: AuthorizationServiceConfiguration(authorizationEndpoint: '<authorization_endpoint>',  tokenEndpoint: '<token_endpoint>', endSessionEndpoint: '<end_session_endpoint>'),
                      scopes: [...]
                    ),
                  );
```

Upon completing the request successfully, the method should return an object (the `result` variable in the above sample code is an instance of the `AuthorizationTokenResponse` class) that contain details that should be stored for future use e.g. access token, refresh token etc.

If you would prefer to not have the automatic code exchange to happen then can call the `authorize` method instead of the `authorizeAndExchangeCode` method. This will return an instance of the `AuthorizationResponse` class that will contain the nonce value and code verifier (note: code verifier is used as part of implement PKCE) that AppAuth generated when issuing the authorization request, the authorization code and additional parameters should they exist. The nonce, code verifier and authorization code would need to be stored so they can then be reused to exchange the code later on e.g.

```dart
final TokenResponse result = await appAuth.token(TokenRequest('<client_id>', '<redirect_url>',
        authorizationCode: '<authorization_code>',
        discoveryUrl: '<discovery_url>',
        codeVerifier: '<code_verifier>',
        nonce: 'nonce',
        scopes: ['openid','profile', 'email', 'offline_access', 'api']));
```

Reusing the nonce and code verifier is particularly important as the AppAuth SDKs (especially on Android) may return an error (e.g. ID token validation error due to nonce mismatch) if this isn't done

### Detecting user cancellation

Both the `authorize` and `authorizeAndExchangeCode` launch the user into a browser which they can cancel. This shouldn't be considered an error and should be handled gracefully.

```dart
try {
  await appAuth.authorize(...); // Or authorizeAndExchangeCode(...)
} on FlutterAppAuthUserCancelledException catch (e) {
  // Handle user cancellation
}
```

### Refreshing tokens

Some providers may return a refresh token that could be used to refresh short-lived access tokens. A request to get a new access token before it expires could be made that would like similar to the following code

```dart
final TokenResponse result = await appAuth.token(TokenRequest('<client_id>', '<redirect_url>',
        discoveryUrl: '<discovery_url>',
        refreshToken: '<refresh_token>',
        scopes: ['openid','profile', 'email', 'offline_access', 'api']));
```

### End session

If your server has an [end session endpoint](https://openid.net/specs/openid-connect-rpinitiated-1_0.html), you can trigger an end session request that is typically used for logging out of the built-in browser with code similar to what's shown below

```dart
await appAuth.endSession(EndSessionRequest(
          idTokenHint: '<idToken>',
          postLogoutRedirectUrl: '<postLogoutRedirectUrl>',
          serviceConfiguration: AuthorizationServiceConfiguration(authorizationEndpoint: '<authorization_endpoint>', tokenEndpoint: '<token_endpoint>', endSessionEndpoint: '<end_session_endpoint>')));
```

The above code passes an `AuthorizationServiceConfiguration` with all the endpoints defined but alternatives are to specify an `issuer` or `discoveryUrl` like you would with the other APIs in the plugin (e.g. `authorizeAndExchangeCode()`).

### Handling errors

Each of these methods will throw exceptions if anything goes wrong. For example:

```dart

try {
  await appAuth.authorize(...);
} on FlutterAppAuthPlatformException catch (e) {
  final FlutterAppAuthPlatformErrorDetails details = e.details;
  // Handle exceptions based on errors from AppAuth.
} catch (e) {
  // Handle other errors.
}

The `FlutterAppAuthPlatformErrorDetails` object contains all the error information from the underlying platform's AppAuth SDK.

This includes the error codes specified in the [RFC](https://datatracker.ietf.org/doc/html/rfc6749#section-5.2).

```

### Ephemeral Sessions (iOS and macOS only)
On iOS (versions 13 and above) and macOS you can use the option `preferEphemeralSession = true` to start an 
[ephemeral browser session](https://developer.apple.com/documentation/foundation/urlsessionconfiguration/1410529-ephemeral)
to sign in and sign out.

With an ephemeral session there will be no warning like `"app_name" Wants to Use "domain_name" to Sign In` on iOS.

The option `preferEphemeralSession = true` must only be used for the end session call if it is also used for the sign in call. 
Otherwise, there will be still an active login session in the browser.

## Android setup

Go to the `build.gradle.kts` file for your Android app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value:

```kotlin

android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders.putAll(
            mapOf(
                "appAuthRedirectScheme" to "<your_custom_scheme>"
            )
        )
    }
}
```

If you're using `build.gradle`:


```groovy

android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders += [
                'appAuthRedirectScheme': '<your_custom_scheme>'
        ]
    }
}
```

Alternatively, the redirect URI can be directly configured by adding an
intent-filter for AppAuth's RedirectUriReceiverActivity to your
AndroidManifest.xml:

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools"
    package="com.example.my_app">
...
<activity
        android:name="net.openid.appauth.RedirectUriReceiverActivity"
        android:theme="@style/Theme.AppCompat.Translucent.NoTitleBar"
        android:exported="true"
        tools:node="replace">
    <intent-filter>
        <action android:name="android.intent.action.VIEW"/>
        <category android:name="android.intent.category.DEFAULT"/>
        <category android:name="android.intent.category.BROWSABLE"/>
        <data android:scheme="<your_custom_scheme>"
              android:host="<your_custom_host>"/>
    </intent-filter>
</activity>
...
```

Please ensure that value of `<your_custom_scheme>` is all in lowercase as there've been reports from the community who had issues with redirects if there were any capital letters. You may also notice the `+=` operation is applied on `manifestPlaceholders` instead of `=`. This is intentional and required as newer versions of the Flutter SDK has made some changes underneath the hood to deal with multidex. Using `=` instead of `+=` can lead to errors like the following

```
Attribute application@name at AndroidManifest.xml:5:9-42 requires a placeholder substitution but no value for <applicationName> is provided.
```

If you see this error then update your `build.gradle` to use `+=` instead.

### Troubleshooting

#### No Redirect to app after login

If you're experiencing issues where the authorization flow does not return to your Flutter app, even though the intent filter is correctly set and `RedirectUriReceiverActivity` is invoked, the issue might be due to the following line in your `AndroidManifest.xml`: `android:taskAffinity=""`. Removing it fixes the [issue](https://github.com/MaikuB/flutter_appauth/issues/503#issuecomment-2165906205)

## iOS/macOS setup

Go to the `Info.plist` for your iOS/macOS app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value


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

Note: iOS apps generate a file called `cache.db` which contains the table `cfurl_cache_receiver_data`. This table will contain the access token obtained after the login is completed. If the potential data leak represents a threat for your application then you can disable the information caching for the entire iOS app (ex. https://kunalgupta1508.medium.com/data-leakage-with-cache-db-2d311582cf23).

### Using https redirect URIs on iOS 17.4+

Starting with iOS 17.4, you can use an `https` redirect URI (a universal-link-style URL such as `https://app.example.com/callback`) instead of a custom scheme. When the redirect URL you pass uses the `https` scheme, the plugin automatically starts the `ASWebAuthenticationSession` using Apple's `callbackWithHTTPSHost:path:` API. No Dart API change is required — you just pass an `https` redirect URL.

This only applies to iOS 17.4 and newer. The plugin's minimum deployment target is unchanged, and the feature is gated behind a runtime `@available(iOS 17.4, *)` check so older devices are unaffected. However, the API genuinely does not exist before 17.4, so on earlier versions an `https` redirect cannot work. If you need to support devices below 17.4, branch on the OS version and fall back to a custom scheme:

```dart
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';

Future<String> redirectUrl() async {
  if (Platform.isIOS) {
    final info = await DeviceInfoPlugin().iosInfo;
    final parts = info.systemVersion.split('.');
    final major = int.tryParse(parts.elementAt(0)) ?? 0;
    final minor = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
    final supportsHttps = major > 17 || (major == 17 && minor >= 4);
    if (supportsHttps) {
      return 'https://app.example.com/oauth/callback';
    }
  }
  return 'com.example.app://oauth/callback';
}
```

If your app's minimum iOS version is already 17.4 or higher, you can drop the branching and always use the `https` redirect URL.

Requirements when using an `https` redirect URI:

1. **Associated Domains entitlement.** Add a `webcredentials` entry (not `applinks`) for the callback host. `ASWebAuthenticationSession`'s `https` callback uses the `webcredentials` association to verify your app owns the domain — it does not go through the universal-link (`applinks`) machinery, and iOS refuses to start the session without it (validation is lenient on the Simulator, so always test on a real device):

   ```xml
   <key>com.apple.developer.associated-domains</key>
   <array>
       <string>webcredentials:app.example.com</string>
   </array>
   ```

2. **`apple-app-site-association` file** hosted at `https://app.example.com/.well-known/apple-app-site-association` listing your app under the `webcredentials` key:

   ```json
   { "webcredentials": { "apps": ["TEAMID.com.example.myapp"] } }
   ```

3. **Register both redirect URIs with your identity provider** if you support older devices, since OAuth servers match `redirect_uri` exactly. Keep the custom scheme registered in `Info.plist` (see above) for the fallback path.


## API docs

API docs can be found [here](https://pub.dartlang.org/documentation/flutter_appauth/latest/)

## FAQs

**When connecting to Azure B2C or Azure AD, the login request redirects properly on Android but not on iOS. What's going on?**

The AppAuth iOS SDK has some logic to validate the redirect URL to see if it should be responsible for processing the redirect. This appears to be failing under certain circumstances. Adding a trailing slash to the redirect URL specified in your code has been reported to fix the issue.
