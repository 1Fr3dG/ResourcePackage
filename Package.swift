// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ResourcePackage",
    products: [
        .library(
            name: "ResourcePackage",
            targets: ["ResourcePackage"]),
    ],
    dependencies: [
        .package(url: "https://github.com/1Fr3dG/TextFormater", from: "1.0.0"),
        .package(url: "https://github.com/1Fr3dG/SimpleEncrypter", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "ResourcePackage",
            dependencies: ["SimpleEncrypter", "TextFormater"],
            path: "Sources",
            sources: ["ResourcePackage.swift"]
            )
    ]
)
