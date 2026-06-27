## [1.0.0]

* Initial release of the web implementation of `flutter_appauth`.
* Wraps the official AppAuth-JS (`@openid/appauth`) SDK, vendored as a bundled
  browser build (`assets/appauth.bundle.js`) and loaded at runtime.
* Supports the authorization code flow with PKCE via a full-page redirect,
  OpenID Connect discovery (`issuer`/`discoveryUrl`), token exchange, token
  refresh and RP-initiated end session.
