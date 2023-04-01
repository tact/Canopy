import Dependencies

private enum CanopyKey: DependencyKey {
  static let liveValue: CanopyType = Canopy()
  static let testValue: CanopyType = MockCanopy()
  static let previewValue: CanopyType = MockCanopy()
}

extension DependencyValues {
  /// Canopy packaged as CloudKit dependency via swift-dependencies.
  public var cloudKit: CanopyType {
    get { self[CanopyKey.self] }
    set { self[CanopyKey.self] = newValue }
  }
}
