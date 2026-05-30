// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "PhoneInboxCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "PhoneInboxCore", targets: ["PhoneInboxCore"])
    ],
    targets: [
        .target(name: "PhoneInboxCore"),
        .testTarget(
            name: "PhoneInboxCoreTests",
            dependencies: ["PhoneInboxCore"]
        )
    ]
)
