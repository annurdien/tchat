// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tchat",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "tchat"
        ),
        .testTarget(
            name: "tchatTests",
            dependencies: ["tchat"]
        ),
    ]
)
