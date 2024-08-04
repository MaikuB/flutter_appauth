## Environment setup

`flutter_appauth` uses [Melos](https://melos.invertase.dev) to manage the monorepo project.

To install Melos, run the following command from a terminal/command prompt:

```
dart pub global activate melos
```

At the root of your locally cloned repository bootstrap the all dependencies and link them locally

```
melos bootstrap
```

This removes the need for providing manual [`dependency_overrides`](https://dart.dev/tools/pub/pubspec). There's no need to run `flutter pub get` either. All the packages, example app and tests will run for the locally cloned repository. The workflows setup on GitHub are also configured use Melos to validate changes. For more information on Melos, refer to its [website](https://melos.invertase.dev)