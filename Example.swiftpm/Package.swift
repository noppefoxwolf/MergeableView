// swift-tools-version: 6.3

import AppleProductTypes
import PackageDescription

let package = Package(
    name: "Example",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .iOSApplication(
            name: "Example",
            targets: ["AppModule"],
            bundleIdentifier: "A97D0CCD-D4B0-4CA0-B3A3-A46425CC1991",
            teamIdentifier: "",
            displayVersion: "1.0",
            bundleVersion: "1",
            supportedDeviceFamilies: [
                .pad,
                .phone,
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad])),
            ]
        )
    ],

    dependencies: [
        .package(path: "../")
    ],

    targets: [
        .executableTarget(
            name: "AppModule",

            dependencies: [
                .product(
                    name: "MergeableView",
                    package: "MergeableView"
                )
            ],

            path: "."
        )
    ]
)
