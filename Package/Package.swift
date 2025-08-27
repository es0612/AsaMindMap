// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AsaMindMap",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [
        .library(name: "MindMapCore", targets: ["MindMapCore"]),
        .library(name: "MindMapUI", targets: ["MindMapUI"]),
        .library(name: "DataLayer", targets: ["DataLayer"]),
        .library(name: "NetworkLayer", targets: ["NetworkLayer"]),
        .library(name: "DesignSystem", targets: ["DesignSystem"])
    ],
    dependencies: [
        // Testing framework - swift-testing from Apple (iOS 18+/macOS 14+)
    ],
    targets: [
        // MARK: - Core Business Logic
        .target(
            name: "MindMapCore",
            dependencies: []
        ),
        .testTarget(
            name: "MindMapCoreTests",
            dependencies: ["MindMapCore"]
        ),
        
        // MARK: - UI Components
        .target(
            name: "MindMapUI",
            dependencies: ["MindMapCore", "DesignSystem"]
        ),
        .testTarget(
            name: "MindMapUITests",
            dependencies: ["MindMapUI"]
        ),
        
        // MARK: - Data Layer
        .target(
            name: "DataLayer",
            dependencies: ["MindMapCore", "NetworkLayer"],
            exclude: ["CoreData/MindMapDataModel.xcdatamodeld"]
        ),
        .testTarget(
            name: "DataLayerTests",
            dependencies: ["DataLayer"]
        ),
        
        // MARK: - Network Layer
        .target(
            name: "NetworkLayer"
        ),
        .testTarget(
            name: "NetworkLayerTests",
            dependencies: ["NetworkLayer"]
        ),
        
        // MARK: - Design System
        .target(
            name: "DesignSystem"
        ),
        .testTarget(
            name: "DesignSystemTests",
            dependencies: ["DesignSystem"]
        )
    ]
)