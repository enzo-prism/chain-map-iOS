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
                "UI",
                "Services/ChainMapAPIClient.swift"
            ],
            sources: [
                "Models/CorridorModels.swift",
                "Models/CorridorDefinitions.swift",
                "Services/CaltransKMLService.swift",
                "Services/LiveData/LiveDataConfiguration.swift",
                "Services/LiveData/CaltransModels.swift",
                "Services/LiveData/CaltransCWWP2Client.swift",
                "Services/LiveData/LiveDataUtilities.swift",
                "Services/LiveData/Nevada511Client.swift",
                "Services/LiveData/DotFeedsService.swift",
                "Sources/Weather/SnowfallPoints.swift",
                "Sources/Weather/SnowfallModels.swift",
                "Sources/Weather/OpenMeteoSnowfallClient.swift",
                "Sources/Weather/SnowfallService.swift",
                "Sources/Weather/SnowfallConfiguration.swift"
            ]
        ),
        .testTarget(
            name: "ChainMapCoreTests",
            dependencies: ["ChainMapCore"],
            path: "chain-map-tests",
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
