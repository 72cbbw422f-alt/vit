// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VITALCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "VITALCore", targets: ["VITALCore"])],
    targets: [
        .target(name: "VITALCore", path: "VITAL/Models", sources: ["RecoveryEngine.swift", "SleepSessionCalculator.swift", "PersonalBaselineCalculator.swift"]),
        .testTarget(name: "VITALCoreTests", dependencies: ["VITALCore"], path: "Tests/VITALCoreTests")
    ]
)
