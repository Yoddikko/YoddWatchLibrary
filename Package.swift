// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "YoddWatchLibrary",
    platforms: [
        .iOS(.v14), .macOS(.v11)
    ],
    products: [
        .library(name: "YoddWatchLibrary", targets: ["YoddWatchLibrary"])
    ],
    targets: [
        .target(name: "YoddWatchLibrary", path: "YoddWatchLibrary"),
        .testTarget(name: "YoddWatchLibraryTests", dependencies: ["YoddWatchLibrary"], path: "YoddWatchLibraryTests")
    ]
)
