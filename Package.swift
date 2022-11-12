// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Tokenizers",
    products: [
        .library(
            name: "Tokenizers",
            targets: ["Tokenizers"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Tokenizers",
            dependencies: ["RustTokenizersFFI"],
            linkerSettings: [
                .linkedLibrary("tokenizers")
            ]),
        .target(
            name: "RustTokenizersFFI",
            dependencies: []),
        .testTarget(
            name: "TokenizersTests",
            dependencies: ["Tokenizers"],
            resources: [
                // Copy Tests/TokenizerTests/Files directory into the module.
                // That causes let SPM generate the extension of Bundle.module property.
                .copy("Files")
            ],
            linkerSettings: [
                .unsafeFlags(["-L./target/debug"])
            ]),
    ]
)
