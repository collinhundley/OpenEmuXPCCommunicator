// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Rewind-OpenEmuXPCCommunicator",
    products: [
        .executable(
            name: "OpenEmuXPCCommunicatorAgent", 
            targets: ["OpenEmuXPCCommunicatorAgent"]),
        .library(
            name: "GoRewindProcessCommunicator",
            targets: ["GoRewindProcessCommunicator"])
        ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "OpenEmuXPCCommunicatorShared"),
        .target(
            name: "OpenEmuXPCCommunicatorAgent", 
            dependencies: ["OpenEmuXPCCommunicatorShared"]),
        .target(
            name: "OpenEmuXPCCommunicatorCore", 
            dependencies: ["OpenEmuXPCCommunicatorShared"]),
        .target(
            name: "GoRewindProcessCommunicator", 
            dependencies: ["OpenEmuXPCCommunicatorCore"])
    ]
)
