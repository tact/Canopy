import Dependencies

private enum CanopyKey: DependencyKey, Sendable {
  static let liveValue: CanopyType = Canopy()
}

public extension DependencyValues {
  /// Canopy packaged as CloudKit dependency via swift-dependencies.
  var cloudKit: CanopyType {
    get { self[CanopyKey.self] }
    set { self[CanopyKey.self] = newValue }
  }
}
