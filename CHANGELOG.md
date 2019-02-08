
# 0.0.3
* Fix to infer grant type based on what is provided when creating a token request (currently only refresh token is supported);
* Update README to include link to https://appauth.io
* Update example to include (commented out) code where the authorization and token endpoints can be explicit set instead of relying on discovery to fetch those endpoints

# 0.0.2+1
* Switch example to connect to test instance of IdentityServer4

# 0.0.2
* Fix error when either `discoveryUrl` or `issuer` has been passed to the `AuthorizationTokenRequest` constructor

# 0.0.1+1
* Update the README to add sections for setting up on Android and iOS

## 0.0.1

* Initial release of the plugin.
