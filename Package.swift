// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "StorageProvider",
    defaultLocalization: "en",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "StorageProvider",
            targets: ["StorageProvider"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ggruen/CloudKitSyncMonitor.git", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "StorageProvider",
            dependencies: ["CloudKitSyncMonitor"]),
        .testTarget(
            name: "StorageProviderTests",
            dependencies: ["StorageProvider"]),
    ]
)
