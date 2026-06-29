// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "flutter_appauth",
    platforms: [
        .macOS("10.14")
    ],
    products: [
        .library(name: "flutter-appauth", targets: ["flutter_appauth"])
    ],
    dependencies: [
        .package(url: "https://github.com/openid/AppAuth-iOS", exact: "2.0.0"),
        .package(name: "FlutterFramework", path: "../FlutterFramework")
    ],
    targets: [
        .target(
            name: "flutter_appauth",
            dependencies: [
                .product(name: "AppAuth", package: "AppAuth-iOS"),
                .product(name: "FlutterFramework", package: "FlutterFramework")
            ],
            resources: [
                .process("PrivacyInfo.xcprivacy")
            ],
            cSettings: [
                .headerSearchPath("include/flutter_appauth")
            ]
        )
    ]
)
