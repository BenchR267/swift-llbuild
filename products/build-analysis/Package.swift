// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuildAnalysis",
    dependencies: [
        // We declare a local dependency on the llbuild Swift API
        .package(path: "../../")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "BuildAnalysis",
            dependencies: ["Commands"]),
        .target(
            name: "Commands",
            dependencies: ["Core", "CriticalPath"]),
        .target(
            name: "Core",
            dependencies: []),
        .target(
            name: "CriticalPath",
            dependencies: ["llbuildSwift"]),
        .testTarget(
            name: "BuildAnalysisTests",
            dependencies: ["BuildAnalysis"]),
    ]
)
