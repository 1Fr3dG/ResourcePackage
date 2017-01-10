import PackageDescription

let package = Package(
    name: "ResourcePackage",
    dependencies: [
        //.Package(url: "https://github.com/dennisweissmann/DeviceKit", majorVersion: 1),
        .Package(url: "https://github.com/1Fr3dG/TextFormater", majorVersion: 1),
        .Package(url: "https://github.com/1Fr3dG/SimpleEncrypter", majorVersion: 0)
    ],
    exclude: ["Example", "packager"]
)
