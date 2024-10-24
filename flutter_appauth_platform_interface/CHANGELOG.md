## [8.0.0]

* **Breaking change** Replaced the `preferEphemeralSession` property in the `AuthorizationRequest`, `AuthorizationTokenRequest` and  `EndSessionRequest` classes with `externalUserAgent`. Thanks to the PR from [john-slow](https://github.com/john-slow). `externalUserAgent` is presented by the newly `ExternalUserAgent` enum that has the following values
    * `asWebAuthenticationSession`: uses the [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) APIs where possible. This is the default value and was the default behaviour behaviour that aligns with what the AppAuth iOS SDK would do in choosing the best available user-agent
    * `ephemeralAsWebAuthenticationSession`: uses an ephemeral session via the [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession) APIs. Applications that previously used `preferEphemeralSession` and specified to be `true` can migrate by specifying this enum value
    * `sfSafariViewController`: uses the [SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller) APIs

## [7.0.1]

* Updated `FlutterAppAuthPlatformErrorDetails` so all the constructor parameters are optional instead of being mandatory through the `required` keyword. This should be a non-breaking change since all the parameters were nullable. Change was done to make code using the class easier to use e.g. when writing tests

## [7.0.0]

* **Breaking change** Bumped minimum Flutter and Dart SDK constraints to 3.13.0 and 3.1.0 respectively
* **Breaking change** all methods have now been made to return non-nullable types
* Updated error handling to expose more details for each platform. Plugin will now throw `FlutterAppAuthUserCancelledException` when an authorization request has been cancelled as a result of the user closing the browser. For other scenarios the plugin will throw `FlutterAppAuthPlatformException`. See the API docs for both classes for more details on the available details. Both exception classes inherit from `PlatformException` so the changes should be backwards compatible

## [6.0.0]

* **Breaking change** Aligned minimum Flutter and Dart SDK constraints to 3.0.0 and 2.17 respectively
* Bumped maximum Dart SDK constraint


## [5.2.0+1]

* Updated code for API docs to avoid lines longer than 80 characters

## [5.2.0]

* Added `preferEphemeralSession` to `EndSessionRequest` Thanks to the PR from [Daniel Ziegler](https://github.com/ziegler-daniel).

## [5.1.0]

* Added ability to specify the `nonce` as part of requests

## [5.0.0]

* **Breaking change** `AuthorizationResponse`'s  constructor now includes `nonce` and has changed to take positional parameters
* `nonce` can now be specified for `TokenRequest` class. This is especially useful on Android as the AppAuth Android SKD had turned on ID token validation that results in nonce mismatch errors. These errors should no longer appear when using the `nonce` value returned by the `AuthorizationResponse` object after calling `authorize()` and passing the value to the `TokenRequest` when calling the `token()` method
* now uses `mocktail` instead of `mockito` as dev dependency for unit tests

## [4.1.0]

* Added `scopes` property to `TokenResponse` class and `AuthorizationTokenResponse` class that inherits from it. Thanks to PR from [leoshusar](https://github.com/leoshusar)

## [4.0.0]

* **Breaking change** `AuthorizationServiceConfiguration` constructor has changed to take named parameters
* Added `endSession()` method, `EndSessionRequest` and `EndSessionResponse` classes to support end session requests

## [3.1.0]

* Added the ability to specify the response mode for authorization requests. This can be done using the `responseMode` parameter  when constructing either an `AuthorizationRequest` or `AuthorizationTokenRequest`. This was done as the AppAuth Android SDK throws an exception when this was done via `additionalParameters`
* Updated Dart SDK constraints

## [3.0.0]

* Migrated to null safety
* `AuthorizationServiceConfiguration` and `AuthorizationResponse` now have `const` constructors

## [2.0.0]

* **Breaking change** Removed the `toMap` methods so that it's not part of the public API surface. This was done as these methods were for internal use. Currently `flutter_appauth` (version 0.8.3) is constrained to depend on versions >= 1.0.2 and < 2.0.0. As it's possible that plugin consumers were calling the methods via the plugin, where the platform interface is a transitive dependency, the platform interface has been bumped to version 2.0.0 instead of 1.1.0 to be safe.
* Added `preferEphemeralSession` to `AuthorizationRequest` and `AuthorizationTokenRequest` classes. Thanks to the PR from [Matthew Smith](https://github.com/matthewtsmith).

## [1.0.2]

* Fixes [issue #86](https://github.com/MaikuB/flutter_appauth/issues/86) where there was an error on casting `tokenAdditionalParameters` property upon calling the `token()` method. Thanks to the PR from [Sven](https://github.com/svendroid)

## [1.0.1]

* Specify the object type for the `instance` property within `FlutterAppAuthPlatform` instead of being dynamic

## [1.0.0+1]

* Add pub badge to readme

## [1.0.0]

* Initial release of platform interface
