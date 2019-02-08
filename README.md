# Flutter AppAuth Plugin

A Flutter bridge for AppAuth

## Getting Started

Please see the example that demonstrates how to sign into the IdentityServer4 demo site (https://demo.identityserver.io). Some limited testing has also been done to confirm that it works with Azure B2C and Google. More documentation and details to come soon.

## Android setup

Go to the `build.gradle` file for your Android app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value

```
...
android {
    ...
    defaultConfig {
        ...
        manifestPlaceholders = [
                'appAuthRedirectScheme': '<your_custom_scheme>'
        ]
    }
}
```

## iOS setup

Go to the `Info.plist` for your iOS app to specify the custom scheme so that there should be a section in it that look similar to the following but replace `<your_custom_scheme>` with the desired value


```
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

**NOTE**: this library uses AndroidX and there is currently a known issuer with Jetifier that affects the use of Chrome Custom Tabs (see https://issuetracker.google.com/issues/119183822). This means that until a fix for it is released, signing will direct users to the browser as opposed to using Chrome Custom Tabs.
