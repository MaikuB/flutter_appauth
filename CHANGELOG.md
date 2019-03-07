# 0.1.1
* Changed the request codes used internally on the Android side to be less than 16 bits. Thanks to the PR from [Dviejopomata](https://github.com/Dviejopomata)

# 0.1.0
* **BREAKING CHANGE** Updated lower bound of the Dark SDK constraints from 2.0.0-dev.68.0 to 2.1.0
* Added more details to the error messages when platform exceptions are raised e.g. when problems occur exchanging the authorization code. Note that there will be differences in the level of details that will be returned on each platform. This is due the differences between the SDKs on each platform

# 0.0.4+1
* No functional changes in this release. Just remove old comment in the code and changes to format the README more nicely

# 0.0.4
* **BREAKING CHANGE** renamed `authorizeAndExchangeToken` method to `authorizeAndExchangeCode` to reflect what happens behind the scenes
* Added an `authorize` method that performs an authorization request to get an authorization code without exchanging it
* Updated README and sample code to demonstrate the use of the `authorize` method, how to exchange the authorization code for tokens and how to perform an authorization request that will retrieve the disocvery document with an issuer instead of the full discovery endpoint URL.

# 0.0.3+1
* Fix code around inferring grant type.
* Update plugin description

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
