// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ChainMapCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "ChainMapCore", targets: ["ChainMapCore"])
    ],
    targets: [
        .target(
            name: "ChainMapCore",
            path: "chain-map",
            exclude: [
                "AGENTS.md",
                "ARCHITECTURE.md",
                "CONTRIBUTING.md",
                "DATA_SOURCES.md",
                "DESIGN.md",
                "PRIVACY.md",
                "README.md",
                "ROADMAP.md",
                "Assets.xcassets",
                "ContentView.swift",
                "chain_mapApp.swift",
                "Features",
                "Services/ChainMapAPIClient.swift"
            ],
            sources: [
                "Models/CorridorModels.swift",
                "Models/CorridorDefinitions.swift",
                "Services/CaltransKMLService.swift"
            ]
        ),
        .testTarget(
            name: "ChainMapCoreTests",
            dependencies: ["ChainMapCore"],
            path: "chain-map-tests"
        )
    ]
)
