// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "VoiceFlow",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "VoiceFlow", targets: ["VoiceFlow"])
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/whisperkit", from: "0.10.0"),
        .package(url: "https://github.com/soffes/HotKey", from: "0.2.1")
    ],
    targets: [
        .executableTarget(
            name: "VoiceFlow",
            dependencies: [
                .product(name: "WhisperKit", package: "whisperkit"),
                "HotKey"
            ],
            path: "Sources"
        )
    ]
)
