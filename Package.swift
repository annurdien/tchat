// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "tchat",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "tchat", targets: ["tchat"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .executableTarget(
            name: "tchat",
            dependencies: [
                .product(name: "Crypto", package: "swift-crypto")
            ],
            linkerSettings: [
                .linkedLibrary("ssl", .when(platforms: [.linux])),
                .linkedLibrary("crypto", .when(platforms: [.linux]))
            ]
        ),
        .testTarget(
            name: "tchatTests",
            dependencies: ["tchat"]
        ),
    ]
)
