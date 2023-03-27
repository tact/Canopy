import CloudKit
import Foundation

/// Archive optionally containing a cursor.
public struct CloudKitCursorArchive: Codable {
  private let data: Data

  public var cursor: CKQueryOperation.Cursor? {
    do {
      let decodedRecord = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
      return decodedRecord as? CKQueryOperation.Cursor
    } catch {
      return nil
    }
  }

  public init(cursor: CKQueryOperation.Cursor?) {
    if let cursor {
      do {
        data = try NSKeyedArchiver.archivedData(withRootObject: cursor, requiringSecureCoding: true)
      } catch {
        data = Data()
      }
    } else {
      data = Data()
    }
  }
}
