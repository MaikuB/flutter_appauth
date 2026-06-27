# flutter_appauth_web

The web implementation of [`flutter_appauth`](https://pub.dev/packages/flutter_appauth).

This package wraps the official [AppAuth-JS](https://github.com/openid/AppAuth-JS)
(`@openid/appauth`) SDK to perform the OAuth 2.0 authorization code flow with
PKCE on the web.

## Usage

This package is
[endorsed](https://docs.flutter.dev/packages-and-plugins/developing-packages#endorsed-federated-plugin),
which means you can use `flutter_appauth` as normal — this package is pulled in
automatically when you build for the web. You should not need to depend on it
directly.

The bundled AppAuth-JS build is shipped with the package and loaded at runtime,
so **no changes to your `web/index.html` are required**.

## How it works

The web flow uses a full-page redirect (popups are not supported):

1. Calling `authorize` or `authorizeAndExchangeCode` when there is no
   authorization response in the current URL starts a new authorization request
   and navigates the browser to the authorization server. The returned future
   does not complete because the page is unloading.
2. After the user authenticates, the authorization server redirects back to your
   `redirectUrl` with a `code` (or an `error`) in the URL.
3. Calling `authorizeAndExchangeCode` again (for example on startup, when
   `Uri.base.queryParameters` contains `code` or `error`) completes the pending
   request and either exchanges the code for tokens or surfaces the error.

A minimal example for handling the redirect on startup:

```dart
@override
void initState() {
  super.initState();
  if (kIsWeb) {
    final Map<String, String> parameters = Uri.base.queryParameters;
    if (parameters.containsKey('code') || parameters.containsKey('error')) {
      _completeSignIn();
    }
  }
}

Future<void> _completeSignIn() async {
  final AuthorizationTokenResponse result =
      await _appAuth.authorizeAndExchangeCode(
    AuthorizationTokenRequest(
      _clientId,
      _redirectUrl,
      issuer: _issuer,
      scopes: _scopes,
    ),
  );
  // ... use the tokens
}
```

### Redirect URL

On the web the `redirectUrl` must be a URL served by your app (for example
`http://localhost:8080/` during development, or your deployed origin), and it
must be registered with your identity provider as an allowed redirect URI.

## Configuration

You can configure endpoints in the same way as on the other platforms:

* `issuer` — endpoints are discovered from
  `<issuer>/.well-known/openid-configuration`.
* `discoveryUrl` — the discovery document URL directly.
* `serviceConfiguration` — explicit `authorizationEndpoint`, `tokenEndpoint` and
  optional `endSessionEndpoint`.

## Rebuilding the AppAuth-JS bundle

The vendored `assets/appauth.bundle.js` is built from `js/`. To regenerate it
(e.g. when bumping the pinned `@openid/appauth` version in `js/package.json`):

```sh
cd js
./build.sh
```

The output is committed to the repository so that consumers never need a
JavaScript toolchain.
