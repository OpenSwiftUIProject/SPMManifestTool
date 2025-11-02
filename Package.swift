// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SPMManifestTool",
    platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .visionOS(.v1)],
    products: [
        .library(
            name: "SPMManifestTool",
            targets: ["SPMManifestTool"]
        ),
    ],
    targets: [
        .target(
            name: "SPMManifestTool",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v5),
            ]
        ),
        .testTarget(
            name: "SPMManifestToolTests",
            dependencies: ["SPMManifestTool"]
        ),
    ]
)
