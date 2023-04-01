// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Canopy",
  defaultLocalization: "en",
  platforms: [.iOS(.v15), .macOS(.v12)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(name: "Canopy", targets: ["Canopy", "CanopyTypes"]),
    .library(name: "CanopyTestTools", targets: ["CanopyTestTools"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(
      url: "https://github.com/groue/Semaphore",
      from: "0.0.6"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "0.2.0"
    )
  ],
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
      path: "Targets/Canopy/Tests"
    ),
    .target(
      name: "CanopyTypes",
      dependencies: [],
      path: "Targets/CanopyTypes/Sources"
    )
  ]
)
