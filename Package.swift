// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "PostlightSwift",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "PostlightSwift",
            targets: ["PostlightSwift"]
        ),
        .executable(
            name: "postlight-cli",
            targets: ["postlight-cli"]
        ),
    ],
    dependencies: [
        // HTML parsing (cross-platform)
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
        // CLI argument parsing
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0"),
        // Async HTTP client for Linux
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.19.0"),
    ],
    targets: [
        .target(
            name: "PostlightSwift",
            dependencies: [
                "SwiftSoup",
                .product(name: "AsyncHTTPClient", package: "async-http-client"),
            ]
        ),
        .executableTarget(
            name: "postlight-cli",
            dependencies: [
                "PostlightSwift",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .testTarget(
            name: "PostlightSwiftTests",
            dependencies: ["PostlightSwift"],
            resources: [
                .copy("Fixtures")
            ]
        ),
    ]
)
