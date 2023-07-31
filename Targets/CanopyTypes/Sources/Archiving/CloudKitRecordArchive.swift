//
//  CloudKitRecordArchive.swift
//  CloudKitRecordArchive
//
//  Created by Andrew Tetlaw on 20/8/21.
//  Copyright © 2021 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

public struct CloudKitRecordArchive: Codable {
  private let data: Data
  
  public var records: [CKRecord] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, CKRecord.self], from: data)
      return decodedRecords as? [CKRecord] ?? []
    } catch {
      return []
    }
  }

  public init(records: [CKRecord]) {
    guard !records.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: records, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}

public extension CloudKitRecordArchive {
  static func + (lhs: CloudKitRecordArchive, rhs: CloudKitRecordArchive) -> CloudKitRecordArchive {
    CloudKitRecordArchive(records: lhs.records + rhs.records)
  }
}
