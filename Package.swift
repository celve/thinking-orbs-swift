// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "thinking-orbs-swift",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "ThinkingOrbsGeometry", targets: ["ThinkingOrbsGeometry"]),
        .library(name: "ThinkingOrbs", targets: ["ThinkingOrbs"]),
    ],
    targets: [
        .target(name: "ThinkingOrbsGeometry"),
        .target(name: "ThinkingOrbs", dependencies: ["ThinkingOrbsGeometry"]),
        // Not products: consumers never build these, but `swift build` still type-checks them.
        // The generator deliberately does not depend on ThinkingOrbsGeometry, so a broken
        // generated file cannot break the tool that regenerates it.
        .executableTarget(name: "OrbsCodegen"),
        .executableTarget(name: "OrbsSnapshot", dependencies: ["ThinkingOrbs"]),
        .testTarget(name: "ThinkingOrbsGeometryTests", dependencies: ["ThinkingOrbsGeometry"]),
        .testTarget(name: "ThinkingOrbsTests", dependencies: ["ThinkingOrbs", "ThinkingOrbsGeometry"]),
    ],
    swiftLanguageModes: [.v6]
)
