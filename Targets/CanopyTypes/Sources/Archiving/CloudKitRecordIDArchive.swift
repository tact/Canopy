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
      let decodedRecords = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecord.ID.self, from: data)
      return decodedRecords ?? []
    } catch {
      return []
    }
  }

  public init(recordIDs: [CKRecord.ID]) {
    guard !recordIDs.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: recordIDs, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}
