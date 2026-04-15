// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CoreEngine",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "CoreEngine",
            targets: ["CoreEngine"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoreEngine",
            dependencies: [],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        ),
        .testTarget(
            name: "CoreEngineTests",
            dependencies: [
                "CoreEngine"
            ],
            path: "Tests/CoreEngineTests",
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
