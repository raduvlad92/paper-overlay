// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "PaperOverlay",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "PaperOverlay",
            path: "Sources/PaperOverlay",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
