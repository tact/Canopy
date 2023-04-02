//
//  CloudKitShareArchive.swift
//  CloudKitShareArchive
//
//  Created by Jaanus Kase on 14/10/21.
//  Copyright © 2021 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

public struct CloudKitShareArchive: Codable {
  private let data: Data

  public var shares: [CKShare] {
    do {
      let decodedShares = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data)
      return decodedShares as? [CKShare] ?? []
    } catch {
      return []
    }
  }

  public init(shares: [CKShare]) {
    guard !shares.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: shares, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}

extension CloudKitShareArchive {
  static func + (lhs: CloudKitShareArchive, rhs: CloudKitShareArchive) -> CloudKitShareArchive {
    CloudKitShareArchive(shares: lhs.shares + rhs.shares)
  }
}
