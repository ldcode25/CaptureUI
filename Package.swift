// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CaptureUI",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "CaptureUI",
            targets: [
                "CaptureUI"
            ]
        )
    ],
    targets: [
        .target(
            name: "CaptureUI",
            dependencies: [
                .target(name: "Logger"),
                .target(name: "SimulatorResources")
            ]
        ),
        .target(
            name: "Logger"
        ),
        .target(
            name: "SimulatorResources"
        )
    ]
)

for target in package.targets {
    var swiftSettings = target.swiftSettings ?? []
    swiftSettings.append(contentsOf: [
        .enableExperimentalFeature("StrictConcurrency"),
    ])
    target.swiftSettings = swiftSettings
}
