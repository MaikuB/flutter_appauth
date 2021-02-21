## 1.0.0-nullsafety.0

* Migrated to null safety

## 0.9.2+6

* [Android] community has reported that there seem to be instances where the plugin encounters a null intent on some devices upon processing a authorisation request. This resulted in a crash before but will now throw a `PlatformException`. Thanks to the PR from [Leon Havenga](https://github.com/li0nza)

## 0.9.2+5

* Updated the Android setup section in the readme to include information for apps targeting Android 11 (API 30) or newer
* [Android] bumped compile SDK version for the plugin to 30
* Updated example app to use compile and target SDK version 30

## 0.9.2+4

* [Android] fix issue [131](https://github.com/MaikuB/flutter_appauth/issues/131) where setting the `allowInsecureConnections` flag to true whilst doing an authorisation or token request didn't behave as expected. Thanks to the PR from [Hongxu Xu](https://github.com/xuhongxu96)

## 0.9.2+3

* [Android] fix issue [79](https://github.com/MaikuB/flutter_appauth/issues/79) where an authorisation request could cause the UI to momentarily hang due to AppAuth trying to warm up the browser

## 0.9.2+2

* Updated example app to use a new client id that works with the demo IdentityServer instance

## 0.9.2+1

* Updated readme to add a link to Auth0 blog post and mention that the value assigned to `appAuthRedirectScheme` within the Android application's `build.gradle` file should be all in lowercase

## 0.9.2

* [iOS] Fixes release build issue about including a non-modular header that came about from release 0.9.1+1. If you experienced issues with 0.9.1+1 (in my experience only occurs if your iOS app uses Swift), please update to 0.9.2

## 0.9.1+1

* Fixes warnings picked up in Xcode raised in issue [123](https://github.com/MaikuB/flutter_appauth/issues/123)

## 0.9.1

* [iOS] Update AppAuth SDK dependency to 1.3.1

## 0.9.0

* Bumped dependency on `flutter_appauth_platform_interface`
* [iOS] The `preferEphemeralSession` property has been added to the `AuthorizationRequest` and `AuthorizationTokenRequest` classes. This enables authorization requests to be done a in private session that won't share cookies and other data with the user's regular browser. This property only works when run on iOS versions 13 and above. Thanks to the PR from [Matthew Smith](https://github.com/matthewtsmith)
* **BREAKING CHANGE** bumping the `flutter_appauth_platform_interface` dependency includes the removal of the `toMap` method from all classes. These methods were used internally by plugin and thus have been removed
* **BREAKING CHANGE** Bumped Gradle plugin to 3.6.3

## 0.8.3

* [Android] Fixed an issue where a `NullPointerException` could occur when too many operations are started at one time. Thanks to the PR from [Josh Burton](https://github.com/athornz)

## 0.8.2

* [Android] Fixed issue [98](https://github.com/MaikuB/flutter_appauth/issues/98) where certain exceptions on Android could prevent the plugin from being able to perform more operations

## 0.8.1

* Bump dependency on `flutter_appauth_platform_interface` to take in fix for casting error that could apply upon calling `token()` method

## 0.8.0

* Migrated plugin to use platform interface
* [Android] Support v2 Android embedding. Example app has been updated accordingly
* **BREAKING CHANGE** removed name constructor from `FlutterAppAuth` class that visible for testing
* **BREAKING CHANGE** when grant type cannot be inferred, this now throws an `ArgumentError` instead of a string containing the error message
* Fixed some formatting issues in the changelog

## 0.7.0+1

* Fix code snippet in readme where the variable for saving the result of the `token()` method should have been of type `TokenResponse` (issue [74](https://github.com/MaikuB/flutter_appauth/issues/74)). Thanks to PR from [Stephen Owens](https://github.com/sowens-csd).

## 0.7.0

* Add minimum version of Flutter (1.12.13+hotfix.5) to address `MissingPluginException` raised issue [66](https://github.com/MaikuB/flutter_appauth/issues/66)
* Update pubspec file of example app to reference plugin in the `dependencies` section instead of `dev_dependencies` to avoid confusion
* Update changelog for 0.6.0 where the minimum Flutter version should have been added

## 0.6.0+1

* Correct changelog entry for 0.6.0 release. Previously reported plugin updated to use Gradle plugin 3.5.2 but should have written 3.5.3

## 0.6.0

* [Android] **BREAKING CHANGE** Bump Gradle plugin to 3.5.3
* [iOS] Fix issue [63](https://github.com/MaikuB/flutter_appauth/issues/63) where `login_hint` and `promptValues` was only passed when using service discovery
* Update pubspec to match latest version of pub
* *NOTE*: this release actually requires updating the latest Flutter stable release (1.12) but missed enforcing it in this release. If you run into a `MissingPluginException` from using this version, please update your Flutter SDK.

## 0.5.0

* [Android] **BREAKING CHANGE** Bump compile and target SDK versions to 29
* [Android] **BREAKING CHANGE** Bump Gradle plugin to version 3.5.2
* Bump example app to use Gradle distribution version 5.4.1

## 0.4.2

* [iOS] Update AppAuth SDK dependency to 1.2 so it works on iOS 13. Thanks to the PR from [Aynur Dinmukhametov](https://github.com/ARDcode)

## 0.4.0+1

* Make it clearer in the readme that AndroidX is required

## 0.4.0

* [iOS] Update AppAuth SDK dependency to 1.1
* Update email address in pubspec.yaml
* Add `GrantTypes` class as a convenience for other developers to use
* **BREAKING CHANGE** `authorize` method has been corrected to accept an instance of the `AuthorizationRequest` class as opposed to an instance of the `AuthorizationTokenRequest` class even though a token isn't being requested

## 0.3.0+1

* Update email address in pubspec.yaml

## 0.3.0

* [iOS] Explicitly set to depend on version 1.0 of the AppAuth iOS SDK
* Added Cirrus CI configuration

## 0.2.1+2

* Updated README to fix section on refreshing tokens where `authorizationCode` was shown in code snippet by mistake

## 0.2.1+1

* Updated README to add a note suggesting developers to check the documentation of the identity provider they plan to use

## 0.2.1

* [iOS] Fix issue with `login_hint` OAuth parameter (specified by the `loginHint` field of the `AuthorizationTokenRequest` and `AuthorizationRequest` classes). Example app has also been updated to demonstrate how to specify it
* Added support for specifying the `prompt` OAuth parameter. This can be specified by populating the `promptValues` field in the either the `AuthorizationTokenRequest` or `AuthorizationRequest` class. Updated example app (note: code is commented out) to demonstrate how to use it

## 0.2.0

* **BREAKING CHANGE** Updated the Android Gradle plugin to version 3.4.0. Applies to both the library and sample app
* Updated README with a note for developers to check to see if their development environment on the Android is up to date as this should now be fixed with the release of Android Studio 3.4
* Updated the Gradle distribution used by the example app to 5.1.1

## 0.1.1

* Changed the request codes used internally on the Android side to be less than 16 bits. Thanks to the PR from [Dviejopomata](https://github.com/Dviejopomata)

## 0.1.0

* **BREAKING CHANGE** Updated lower bound of the Dark SDK constraints from 2.0.0-dev.68.0 to 2.1.0
* Added more details to the error messages when platform exceptions are raised e.g. when problems occur exchanging the authorization code. Note that there will be differences in the level of details that will be returned on each platform. This is due the differences between the SDKs on each platform

## 0.0.4+1

* No functional changes in this release. Just remove old comment in the code and changes to format the README more nicely

## 0.0.4

* **BREAKING CHANGE** renamed `authorizeAndExchangeToken` method to `authorizeAndExchangeCode` to reflect what happens behind the scenes
* Added an `authorize` method that performs an authorization request to get an authorization code without exchanging it
* Updated README and sample code to demonstrate the use of the `authorize` method, how to exchange the authorization code for tokens and how to perform an authorization request that will retrieve the disocvery document with an issuer instead of the full discovery endpoint URL.

## 0.0.3+1

* Fix code around inferring grant type.
* Update plugin description

## 0.0.3

* Fix to infer grant type based on what is provided when creating a token request (currently only refresh token is supported);
* Update README to include link to https://appauth.io
* Update example to include (commented out) code where the authorization and token endpoints can be explicit set instead of relying on discovery to fetch those endpoints

## 0.0.2+1

* Switch example to connect to test instance of IdentityServer4

## 0.0.2

* Fix error when either `discoveryUrl` or `issuer` has been passed to the `AuthorizationTokenRequest` constructor

## 0.0.1+1

* Update the README to add sections for setting up on Android and iOS

## 0.0.1

* Initial release of the plugin.
