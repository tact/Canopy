import CanopyTypes
import CloudKit

public extension ReplayingMockCKContainer {
  struct AccountStatusResult: Codable, Sendable {
    let statusValue: Int
    let canopyError: CanopyError?
    
    public init(status: CKAccountStatus, error: Error?) {
      self.statusValue = status.rawValue
      if let error {
        self.canopyError = CanopyError.accountError(from: error)
      } else {
        self.canopyError = nil
      }
    }
  }
}
