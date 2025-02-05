// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodableStorage",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_15)
    ],
    products: [
        .library(
            name: "CodableStorage",
            targets: ["CodableStorage"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CodableStorage",
            dependencies: [],
            path: "CodableStorage",
            publicHeadersPath: ""),
    ]
)
