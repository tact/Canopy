import CloudKit
import Foundation

/// Archive optionally containing a cursor.
public struct CloudKitCursorArchive: Codable, Sendable {
  private let data: Data

  public var cursor: CKQueryOperation.Cursor? {
    do {
      let decodedRecord = try NSKeyedUnarchiver.unarchivedObject(ofClass: CKQueryOperation.Cursor.self, from: data)
      return decodedRecord
    } catch {
      return nil
    }
  }

  public init(cursor: CKQueryOperation.Cursor?) {
    if let cursor {
      do {
        self.data = try NSKeyedArchiver.archivedData(withRootObject: cursor, requiringSecureCoding: true)
      } catch {
        self.data = Data()
      }
    } else {
      self.data = Data()
    }
  }
}
