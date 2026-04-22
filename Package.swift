// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WebAssemblyApp",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/elementary-swift/elementary-ui", from: "0.2.2"),
        .package(url: "https://github.com/swiftwasm/JavaScriptKit.git", from: "0.50.2"),
    ],
    targets: [
        .executableTarget(
            name: "WebAssemblyApp",
            dependencies: [
                .product(name: "JavaScriptKit", package: "javascriptkit"),
                .product(name: "ElementaryUI", package: "elementary-ui"),
            ],
            exclude: ["entry.js"],
        ),
    ],
    swiftLanguageModes: [.v6]
)
