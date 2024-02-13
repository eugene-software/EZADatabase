// swift-tools-version: 5.7

import PackageDescription

let package = Package(
    name: "EZADatabase",
    platforms: [
            .iOS(.v13)
        ],
    products: [
        .library(
            name: "EZADatabase",
            targets: ["EZADatabase"]),
    ],
    targets: [
        .target(
            name: "EZADatabase",
            dependencies: []),
    ],
    swiftLanguageVersions: [
        .v5
    ]
)
