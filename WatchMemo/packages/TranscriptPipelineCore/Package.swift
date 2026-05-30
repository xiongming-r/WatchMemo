// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TranscriptPipelineCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "TranscriptPipelineCore", targets: ["TranscriptPipelineCore"])
    ],
    targets: [
        .target(name: "TranscriptPipelineCore"),
        .testTarget(
            name: "TranscriptPipelineCoreTests",
            dependencies: ["TranscriptPipelineCore"]
        )
    ]
)
