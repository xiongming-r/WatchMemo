// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WatchMemoMessageCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v14)
    ],
    products: [
        .library(name: "WatchMemoMessageCore", targets: ["WatchMemoMessageCore"])
    ],
    targets: [
        .target(name: "WatchMemoMessageCore"),
        .testTarget(name: "WatchMemoMessageCoreTests", dependencies: ["WatchMemoMessageCore"])
    ]
)
