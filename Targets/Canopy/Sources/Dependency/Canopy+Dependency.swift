import Dependencies

@available(iOS 16.4, macOS 13.3, *)
private enum CanopyKey: DependencyKey, Sendable {
  static let liveValue: CanopyType = Canopy()
  static let testValue: CanopyType = MockCanopy()
  static let previewValue: CanopyType = MockCanopy()
}

@available(iOS 16.4, macOS 13.3, *)
public extension DependencyValues {
  /// Canopy packaged as CloudKit dependency via swift-dependencies.
  var cloudKit: CanopyType {
    get { self[CanopyKey.self] }
    set { self[CanopyKey.self] = newValue }
  }
}
