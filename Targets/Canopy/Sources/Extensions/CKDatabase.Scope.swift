import CloudKit

public extension CKDatabase.Scope {
  var asString: String {
    switch self {
    case .public:
      return "public"
    case .private:
      return "private"
    case .shared:
      return "shared"
    @unknown default:
      fatalError("Unknown database scope")
    }
  }
}
