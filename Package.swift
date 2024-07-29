// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import Foundation
import PackageDescription

var dependencies: [PackageDescription.Package.Dependency] = [
  .package(
    url: "https://github.com/groue/Semaphore",
    from: "0.0.8"
  ),
  .package(
    url: "https://github.com/pointfreeco/swift-dependencies",
    from: "1.0.0"
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
  dependencies.append(.package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"))
}

let package = Package(
  name: "Canopy",
  defaultLocalization: "en",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(name: "Canopy", targets: ["Canopy", "CanopyTypes"]),
    .library(name: "CanopyTestTools", targets: ["CanopyTestTools"])
  ],
  dependencies: dependencies,
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "Canopy",
      dependencies: [
        "Semaphore",
        "CanopyTypes",
        .product(name: "Dependencies", package: "swift-dependencies")
      ],
      path: "Targets/Canopy/Sources"
      // https://danielsaidi.com/blog/2022/05/18/how-to-suppress-linking-warning
      // Canopy by default gives a warning about unsafe code for application extensions. Not sure why it says that.
      // See the above blog post for more info.
      // The following line is OK to have in local development, but in live setting, cannot be used.
      // This could also be obsolete, latest Canopy does not give warnings with extensions any more.
      // Keeping this info here just for a while longer.
      // linkerSettings: [.unsafeFlags(["-Xlinker", "-no_application_extension"])]
    ),
    .target(
      name: "CanopyTestTools",
      dependencies: ["CanopyTypes"],
      path: "Targets/CanopyTestTools/Sources"
    ),
    .testTarget(
      name: "CanopyTests",
      dependencies: ["Canopy", "CanopyTestTools"],
      path: "Targets/Canopy/Tests",
      resources: [
        .process("Fixtures")
      ]
    ),
    .target(
      name: "CanopyTypes",
      dependencies: [],
      path: "Targets/CanopyTypes/Sources"
    )
  ]
)
