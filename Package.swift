// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StickyTasks",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "StickyTasks",
            path: "Sources"
        )
    ]
)
