// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "Thumbrail",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "Thumbrail",
            path: "Sources/Thumbrail",
            linkerSettings: [
                .linkedFramework("IOKit"),
                .linkedFramework("CoreAudio"),
                .linkedFramework("AudioToolbox"),
                .linkedFramework("ServiceManagement"),
            ]
        )
    ]
)
