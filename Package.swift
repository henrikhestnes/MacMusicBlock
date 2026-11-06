// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacMusicBlock",
    platforms: [.macOS(.v13)],
    products: [.executable(name: "MacMusicBlock", targets: ["MacMusicBlock"])],
    targets: [
        .target(name: "MacMusicBlockCore"),
        .executableTarget(name: "MacMusicBlock", dependencies: ["MacMusicBlockCore"]),
        .testTarget(name: "MacMusicBlockCoreTests", dependencies: ["MacMusicBlockCore"])
    ]
)
