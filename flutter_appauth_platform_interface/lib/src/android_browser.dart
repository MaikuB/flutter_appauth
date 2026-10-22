/// Describes a browser (or custom tab implementation) that is allowed to
/// handle an authorization or end session request.
///
/// This is only applicable to Android. Use the `chrome*`, `firefox*` and
/// `samsung*` presets to restrict the request to one of the browsers that
/// AppAuth for Android already recognises, or [AndroidBrowser.custom] to
/// describe a browser that isn't covered by a preset e.g. one pushed to
/// devices via MDM.
class AndroidBrowser {
  const AndroidBrowser._(this.preset)
      : packageName = null,
        signatureHashes = null,
        useCustomTab = null,
        minVersion = null;

  /// Describes a custom browser (or custom tab implementation) by its package
  /// name and signing certificate.
  ///
  /// [packageName] is the browser's package name, e.g. `com.acme.browser`.
  ///
  /// [signatureHashes] are the browser's Base64-encoded, SHA-512 signing
  /// certificate hashes, as returned by AppAuth for Android's
  /// `BrowserDescriptor.generateSignatureHashes`. A browser matches only if
  /// its signing certificates hash to exactly this set. To allow several
  /// signer sets, e.g. before and after a key rotation, add one entry per set.
  ///
  /// [useCustomTab] indicates whether the browser should be used as a Chrome
  /// Custom Tab (`true`) or as a standalone browser (`false`). Defaults to
  /// `true`.
  ///
  /// [minVersion] is the minimum version of the browser that is allowed. When
  /// omitted, any version is allowed.
  const AndroidBrowser.custom({
    required String this.packageName,
    required Set<String> this.signatureHashes,
    bool this.useCustomTab = true,
    this.minVersion,
  }) : preset = null;

  /// Chrome, used as a Chrome Custom Tab.
  static const AndroidBrowser chromeCustomTab =
      AndroidBrowser._('chromeCustomTab');

  /// Chrome, used as a standalone browser.
  static const AndroidBrowser chromeBrowser = AndroidBrowser._('chromeBrowser');

  /// Firefox, used as a Custom Tab.
  static const AndroidBrowser firefoxCustomTab =
      AndroidBrowser._('firefoxCustomTab');

  /// Firefox, used as a standalone browser.
  static const AndroidBrowser firefoxBrowser =
      AndroidBrowser._('firefoxBrowser');

  /// The Samsung Internet browser, used as a Custom Tab.
  static const AndroidBrowser samsungCustomTab =
      AndroidBrowser._('samsungCustomTab');

  /// The Samsung Internet browser, used as a standalone browser.
  static const AndroidBrowser samsungBrowser =
      AndroidBrowser._('samsungBrowser');

  /// The name Android resolves to one of AppAuth for Android's built-in
  /// browser matchers, or `null` for a [AndroidBrowser.custom] entry.
  final String? preset;

  /// The custom browser's package name, or `null` for a preset entry.
  final String? packageName;

  /// The custom browser's Base64-encoded signing certificate hashes, or
  /// `null` for a preset entry.
  final Set<String>? signatureHashes;

  /// Whether the custom browser should be used as a Custom Tab, or `null` for
  /// a preset entry.
  final bool? useCustomTab;

  /// The minimum allowed version of the custom browser, or `null` for a
  /// preset entry or when any version is allowed.
  final String? minVersion;

  /// Converts this to a map that can be sent over the method channel.
  Map<String, Object?> toMap() {
    if (preset != null) {
      return <String, Object?>{'preset': preset};
    }
    return <String, Object?>{
      'packageName': packageName,
      'signatureHashes': signatureHashes?.toList(),
      'useCustomTab': useCustomTab,
      'minVersion': minVersion,
    };
  }
}

/// A browser (or custom tab implementation) installed on an Android device, as
/// returned by `getInstalledAndroidBrowsers`.
///
/// This is meant for development: use it on a test device to look up the
/// [signatureHashes] of a browser you want to pin, then hard-code them in an
/// [AndroidBrowser.custom] entry. Passing hashes read at runtime straight back
/// into `androidAllowedBrowsers` pins nothing, as a look-alike app installed
/// under the same package name would be read and allowed too.
class InstalledAndroidBrowser {
  const InstalledAndroidBrowser({
    required this.packageName,
    required this.version,
    required this.signatureHashes,
    required this.useCustomTab,
  });

  /// Creates an instance from a map received over the method channel.
  factory InstalledAndroidBrowser.fromMap(Map<dynamic, dynamic> map) {
    return InstalledAndroidBrowser(
      packageName: map['packageName'],
      version: map['version'],
      signatureHashes:
          (map['signatureHashes'] as List<dynamic>).cast<String>().toSet(),
      useCustomTab: map['useCustomTab'],
    );
  }

  /// The browser's package name, e.g. `com.android.chrome`.
  final String packageName;

  /// The browser's version name, or `null` if it doesn't declare one.
  final String? version;

  /// The browser's Base64-encoded, SHA-512 signing certificate hashes, in the
  /// form [AndroidBrowser.custom] expects.
  final Set<String> signatureHashes;

  /// Whether this entry describes the browser used as a Custom Tab. A browser
  /// that supports Custom Tabs is listed twice, once for each mode.
  final bool useCustomTab;

  @override
  String toString() => 'InstalledAndroidBrowser(packageName: $packageName, '
      'version: $version, signatureHashes: $signatureHashes, '
      'useCustomTab: $useCustomTab)';
}
