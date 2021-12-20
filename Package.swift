import PackageDescription

let package = Package(
    name: "CodableStorage",
    platforms: [
        .iOS(.v12)
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
