// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WatchDeliveryCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v14)
    ],
    products: [
        .library(name: "WatchDeliveryCore", targets: ["WatchDeliveryCore"])
    ],
    targets: [
        .target(name: "WatchDeliveryCore"),
        .testTarget(name: "WatchDeliveryCoreTests", dependencies: ["WatchDeliveryCore"])
    ]
)
