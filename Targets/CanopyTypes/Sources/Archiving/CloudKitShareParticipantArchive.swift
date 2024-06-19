//
//  CloudKitShareArchive.swift
//  CloudKitShareArchive
//
//  Created by Jaanus Kase on 14/10/21.
//  Copyright © 2021 Jaanus Kase. All rights reserved.
//

import CloudKit
import Foundation

public struct CloudKitShareParticipantArchive: Codable, Sendable {
  private let data: Data

  public var shareParticipants: [CKShare.Participant] {
    do {
      let decodedShareParticipants = try NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, CKShare.Participant.self], from: data)
      return decodedShareParticipants as? [CKShare.Participant] ?? []
    } catch {
      return []
    }
  }

  public init(shareParticipants: [CKShare.Participant]) {
    guard !shareParticipants.isEmpty else {
      self.data = Data()
      return
    }

    do {
      self.data = try NSKeyedArchiver.archivedData(withRootObject: shareParticipants, requiringSecureCoding: true)
    } catch {
      self.data = Data()
    }
  }
}

extension CloudKitShareParticipantArchive {
  static func + (lhs: CloudKitShareParticipantArchive, rhs: CloudKitShareParticipantArchive) -> CloudKitShareParticipantArchive {
    CloudKitShareParticipantArchive(shareParticipants: lhs.shareParticipants + rhs.shareParticipants)
  }
}
