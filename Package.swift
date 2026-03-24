// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "TypeLingo",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "typelingo", targets: ["LiveTranslateApp"])
    ],
    targets: [
        .executableTarget(
            name: "LiveTranslateApp",
            path: "Sources/LiveTranslateApp"
        ),
        .testTarget(
            name: "LiveTranslateAppTests",
            dependencies: ["LiveTranslateApp"],
            path: "Tests/LiveTranslateAppTests"
        )
    ]
)
