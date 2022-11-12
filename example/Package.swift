// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Example",
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "PretrainedTokenizerExample",
            dependencies: [
                .product(name: "Tokenizers", package: "tokenizers-swift")
            ]
        ),
        .executableTarget(
            name: "TrainingTokenizerExample",
            dependencies: [
                .product(name: "Tokenizers", package: "tokenizers-swift")
            ]),
    ]
)
