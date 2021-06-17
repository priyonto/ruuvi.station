// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "RuuviUser",
    platforms: [.macOS(.v10_15), .iOS(.v10)],
    products: [
        .library(
            name: "RuuviUser",
            targets: ["RuuviUser"])
    ],
    dependencies: [
        .package(url: "https://github.com/kishikawakatsumi/KeychainAccess", from: "4.2.1")
    ],
    targets: [
        .target(
            name: "RuuviUser",
            dependencies: [
                "KeychainAccess"
            ]
        ),
        .testTarget(
            name: "RuuviUserTests",
            dependencies: ["RuuviUser"])
    ]
)
