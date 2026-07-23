// swift-tools-version: 6.2
import PackageDescription

/// Match the app project's language mode (Swift 5) and default MainActor isolation.
let settings: [SwiftSetting] = [.swiftLanguageMode(.v5), .defaultIsolation(MainActor.self)]

let package = Package(
    name: "Core",
    platforms: [.macOS("26.3")],
    products: [
        .library(name: "Core", targets: ["Core"]),
        .library(name: "LiveAdapters", targets: ["LiveAdapters"]),
    ],
    targets: [
        .target(name: "Core", swiftSettings: settings),
        .target(name: "LiveAdapters", dependencies: ["Core"], swiftSettings: settings),
        .testTarget(name: "CoreTests", dependencies: ["Core"], swiftSettings: settings),
    ]
)
