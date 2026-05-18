// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CodeShieldMac",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "CodeShieldCore", targets: ["CodeShieldCore"]),
        .executable(name: "CodeShieldMac", targets: ["CodeShieldMac"]),
        .executable(name: "CodeShieldSmoke", targets: ["CodeShieldSmoke"]),
        .executable(name: "CodeShieldOCRDebug", targets: ["CodeShieldOCRDebug"]),
    ],
    targets: [
        .target(name: "CodeShieldCore"),
        .executableTarget(
            name: "CodeShieldMac",
            dependencies: ["CodeShieldCore"]
        ),
        .executableTarget(
            name: "CodeShieldSmoke",
            dependencies: ["CodeShieldCore"]
        ),
        .executableTarget(
            name: "CodeShieldOCRDebug",
            dependencies: ["CodeShieldCore"]
        ),
        .testTarget(
            name: "CodeShieldCoreTests",
            dependencies: ["CodeShieldCore"]
        ),
    ]
)
