import Foundation
#if os(iOS)
  import UIKit
#endif

public enum FetchRecordChangesResult: UInt, Codable {
  case newData, noData, failed

  #if os(iOS)
    public var backgroundFetchResult: UIBackgroundFetchResult {
      switch self {
      case .newData:
        return .newData
      case .noData:
        return .noData
      case .failed:
        return .failed
      }
    }
  #endif
}
