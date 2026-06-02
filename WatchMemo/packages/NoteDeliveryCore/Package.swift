// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "NoteDeliveryCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "NoteDeliveryCore",
            targets: ["NoteDeliveryCore"]
        )
    ],
    targets: [
        .target(name: "NoteDeliveryCore"),
        .testTarget(
            name: "NoteDeliveryCoreTests",
            dependencies: ["NoteDeliveryCore"]
        )
    ]
)
