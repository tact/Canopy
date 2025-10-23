// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

var dependencies: [PackageDescription.Package.Dependency] = [
  .package(
    url: "https://github.com/groue/Semaphore",
    from: "0.1.0"
  ),
  .package(
    url: "https://github.com/pointfreeco/swift-dependencies",
    from: "1.10.0"
  )
]

// The SPI_BUILDER environment variable enables documentation building
// in Swift Package Index, should we ever host the docs there.
// See <https://github.com/SwiftPackageIndex/SwiftPackageIndex-Server/issues/2122>
// for more information.
//
// SPI_BUILDER also enables the `just doc-preview` command.
//
// This approach was lifted from GRDB Package.swift.
if ProcessInfo.processInfo.environment["SPI_BUILDER"] == "1" {
  dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.0"))
}

let package = Package(
  name: "Canopy",
  defaultLocalization: "en",
  platforms: [.iOS(.v18), .macOS(.v15)],
  products: [
    .library(name: "Canopy", targets: ["Canopy"]),
    .library(name: "CanopyTestTools", targets: ["CanopyTestTools"])
  ],
  dependencies: dependencies,
  targets: [
    .target(
      name: "Canopy",
      dependencies: [
        "Semaphore",
        .product(name: "Dependencies", package: "swift-dependencies")
      ],
      path: "Targets/Canopy/Sources"
    ),
    .target(
      name: "CanopyTestTools",
      dependencies: ["Canopy"],
      path: "Targets/CanopyTestTools/Sources"
    ),
    .testTarget(
      name: "CanopyTests",
      dependencies: ["Canopy", "CanopyTestTools"],
      path: "Targets/Canopy/Tests",
      resources: [
        .process("Fixtures")
      ]
    )
  ]
)
