// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "LongAudioProcessingCore",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
        .macOS(.v14)
    ],
    products: [
        .library(name: "LongAudioProcessingCore", targets: ["LongAudioProcessingCore"])
    ],
    targets: [
        .target(name: "LongAudioProcessingCore"),
        .testTarget(name: "LongAudioProcessingCoreTests", dependencies: ["LongAudioProcessingCore"])
    ]
)
