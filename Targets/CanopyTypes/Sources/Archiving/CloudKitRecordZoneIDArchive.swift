//
//  CloudKitRecordZoneIDArchive.swift
//  Tact
//
//  Created by Andrew Tetlaw on 5/1/2022.
//  Copyright © 2022 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

public struct CloudKitRecordZoneIDArchive: Codable {
  private let data: Data

  public var zoneIDs: [CKRecordZone.ID] {
    do {
      let decodedRecords = try NSKeyedUnarchiver.unarchivedArrayOfObjects(ofClass: CKRecordZone.ID.self, from: data)
      return decodedRecords ?? []
    } catch {
      return []
    }
  }

  public init(zoneIDs: [CKRecordZone.ID]) {
    guard !zoneIDs.isEmpty else {
      data = Data()
      return
    }

    do {
      data = try NSKeyedArchiver.archivedData(withRootObject: zoneIDs, requiringSecureCoding: true)
    } catch {
      data = Data()
    }
  }
}
