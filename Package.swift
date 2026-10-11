// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TextSnap",
    platforms: [.macOS(.v15)],
    products: [
        .executable(name: "TextSnap", targets: ["TextSnap"]),
    ],
    targets: [
        // Pure layout logic: OCR lines in, structured text out. No AppKit, no Vision.
        .target(name: "TextSnapCore"),
        // macOS shell: hotkey, screen capture, Vision OCR, pasteboard, menu bar.
        .executableTarget(
            name: "TextSnap",
            dependencies: ["TextSnapCore"]
        ),
        .testTarget(
            name: "TextSnapCoreTests",
            dependencies: ["TextSnapCore"]
        ),
    ]
)
