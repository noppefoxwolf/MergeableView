// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MergeableView",
    platforms: [.iOS(.v26)],
    products: [
        .library(
            name: "MergeableView",
            targets: ["MergeableView"]
        )
    ],
    targets: [
        .target(
            name: "MergeableView"
        ),
        .testTarget(
            name: "MergeableViewTests",
            dependencies: ["MergeableView"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
