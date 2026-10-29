// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "EdgePanel",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "EdgePanel",
            path: "Sources/EdgePanel",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
