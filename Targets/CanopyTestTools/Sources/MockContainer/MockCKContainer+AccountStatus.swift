import CanopyTypes
import CloudKit

extension MockCKContainer {
  public struct AccountStatusResult: Codable {
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
