## [3.0.0-nullsafety.3]

* Updated `plugin_platform_interface` version requirement

## [3.0.0-nullsafety.2]

* `clientId` and `redirectUrl` are now non-nullable

## [3.0.0-nullsafety.1]

* Updated constraints for `plugin_platform_interface` dependency

## [3.0.0-nullsafety.0]

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