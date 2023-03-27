//
//  CloudKitRecordIDArchive.swift
//  CloudKitRecordIDArchive
//
//  Created by Andrew Tetlaw on 20/8/21.
//  Copyright © 2021 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

public struct CloudKitRecordIDArchive: Codable {
  private let data: Data

  public var recordIDs: [CKRecord.ID] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
      return decodedRecords as? [CKRecord.ID] ?? []
    } catch {
      return []
    }
  }

  public init(recordIDs: [CKRecord.ID]) {
    guard !recordIDs.isEmpty else {
      data = Data()
      return
    }

    do {
      data = try NSKeyedArchiver.archivedData(withRootObject: recordIDs, requiringSecureCoding: true)
    } catch {
      data = Data()
    }
  }
}
