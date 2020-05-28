## [2.0.0]

* **BREAKING CHANGE** the `toMap` methods of all classes have been removed from the public API surface. Currently `flutter_appauth` (version 0.8.3) is constrained to depend on versions >= 1.0.2 and < 2.0.0. As it's possible that plugin consumers were calling the methods via the plugin, where the platform interface is a transitive dependency, the platform interface has been bumped to version 2.0.0 instead of 1.1.0 to be safe.
* Added `preferEphemeralSession` to `AuthorizationRequest` and `AuthorizationTokenRequest` classes. Thanks to the PR from [Matthew Smith](https://github.com/matthewtsmith).

## [1.0.2]

* Fixes [issue #86](https://github.com/MaikuB/flutter_appauth/issues/86) where there was an error on casting `tokenAdditionalParameters` property upon calling the `token()` method. Thanks to the PR from [Sven](https://github.com/svendroid)

## [1.0.1]

* Specify the object type for the `instance` property within `FlutterAppAuthPlatform` instead of being dynamic

## [1.0.0+1]

* Add pub badge to readme

## [1.0.0]

* Initial release of platform interface