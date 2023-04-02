@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

final class ContainerAPITests: XCTestCase {
  func test_userRecordID_success() async {
    let recordID = CKRecord.ID(recordName: "SomeUserID")
    let container = ReplayingMockCKContainer(
      operationResults: [
        .userRecordID(
          .init(
            userRecordID: recordID,
            error: nil
          )
        )
      ]
    )
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 0))
    let result = try? await containerAPI.userRecordID.get()
    XCTAssertEqual(result, recordID)
  }
  
  func test_userRecordID_failure() async {
    let ckError = CKError(CKError.Code.networkUnavailable)
    let container = ReplayingMockCKContainer(
      operationResults: [
        .userRecordID(.init(userRecordID: nil, error: ckError))
      ]
    )
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.userRecordID.get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: ckError))
    }
  }
  
  func test_accountStatus_success() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil))
      ]
    )
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 0))
    let result = try? await containerAPI.accountStatus.get()
    XCTAssertEqual(result, .available)
  }
  
  func test_accountStatus_success_multiple_requests() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil))
      ]
    )
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 0))
    let result = try! await containerAPI.accountStatus.get()
    XCTAssertEqual(result, .available)
    
    // Try more requests, so there are more requests than inputs.
    // mock accountStatus API returns the last status without dequeueing it.
    let result2 = try! await containerAPI.accountStatus.get()
    let result3 = try! await containerAPI.accountStatus.get()
    XCTAssertEqual(result2, .available)
    XCTAssertEqual(result3, .available)
  }
  
  func test_accountStatus_failure() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(
          .init(
            status: .couldNotDetermine,
            error: CKError(CKError.Code.accountTemporarilyUnavailable)
          )
        )
      ]
    )
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.accountStatus.get()
    } catch {
      XCTAssertEqual(error as! CanopyError, .ckAccountError("The operation couldn’t be completed. (CKErrorDomain error 36.)", CKError.Code.accountTemporarilyUnavailable.rawValue))
    }
  }
  
  func test_accountStatus_stream() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil)),
        .accountStatus(.init(status: .noAccount, error: nil)),
        .accountStatus(.init(status: .couldNotDetermine, error: CKError(CKError.Code.accountTemporarilyUnavailable))),
        .accountStatus(.init(status: .restricted, error: nil))
      ]
    )
    
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 3))
    var statuses: [CKAccountStatus] = []
    let stream = try? await containerAPI.accountStatusStream.get()
    for await status in stream! {
      statuses.append(status)
      if statuses.count == 3 { break }
    }
    XCTAssertEqual(statuses, [.available, .noAccount, .restricted])
  }
  
  func test_accountStatus_twoStreams() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil)),
        .accountStatus(.init(status: .noAccount, error: nil)),
        .accountStatus(.init(status: .restricted, error: nil))
      ]
    )
    
    let containerAPI = CKContainerAPI(container, accountChangedSequence: .mock(elementsToProduce: 2))
    var statuses1: [CKAccountStatus] = []
    
    let stream1 = try! await containerAPI.accountStatusStream.get()
    
    do {
      let _ = try await containerAPI.accountStatusStream.get()
    } catch {
      XCTAssertEqual(error as! CKContainerAPIError, .onlyOneAccountStatusStreamSupported)
    }
    
    for await status in stream1 {
      statuses1.append(status)
      if statuses1.count == 3 { break }
    }
    
    let expected: [CKAccountStatus] = [.available, .noAccount, .restricted]
    XCTAssertEqual(statuses1, expected)
  }
  
  func test_fetch_share_participants_success() async {
    let lookupInfo1 = CKUserIdentity.LookupInfo(emailAddress: "email@example.com")
    let lookupInfo2 = CKUserIdentity.LookupInfo(emailAddress: "email2@example.com")

    let mockContainer = ReplayingMockCKContainer(
      operationResults: [
        .fetchShareParticipants(
          .init(
            perShareParticipantResults: [
              .init(
                lookupInfo: lookupInfo1,
                result: .success(CKShare.Participant.mock)
              ),
              .init(
                lookupInfo: lookupInfo2,
                result: .success(CKShare.Participant.mock)
              )
            ],
            fetchShareParticipantsResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let containerAPI = CKContainerAPI(mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    let participants = try? await containerAPI.fetchShareParticipants(with: [lookupInfo1, lookupInfo2], qualityOfService: .default).get()
    XCTAssertEqual(participants, [CKShare.Participant.mock, CKShare.Participant.mock])
  }
  
  func test_fetch_share_participants_record_error() async {
    let lookupInfo1 = CKUserIdentity.LookupInfo(emailAddress: "email@example.com")
    let lookupInfo2 = CKUserIdentity.LookupInfo(emailAddress: "email2@example.com")

    let mockContainer = ReplayingMockCKContainer(
      operationResults: [
        .fetchShareParticipants(
          .init(
            perShareParticipantResults: [
              .init(
                lookupInfo: lookupInfo1,
                result: .failure(CKError(CKError.Code.badContainer))
              ),
              .init(
                lookupInfo: lookupInfo2,
                result: .success(CKShare.Participant.mock)
              )
            ],
            fetchShareParticipantsResult: .init(result: .success(()))
          )
        )
      ]
    )
    
    let containerAPI = CKContainerAPI(mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.fetchShareParticipants(with: [lookupInfo1, lookupInfo2], qualityOfService: .default).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.badContainer)))
    }
  }
  
  func test_fetch_share_participants_result_error() async {
    let lookupInfo1 = CKUserIdentity.LookupInfo(emailAddress: "email@example.com")
    let lookupInfo2 = CKUserIdentity.LookupInfo(emailAddress: "email2@example.com")

    let mockContainer = ReplayingMockCKContainer(
      operationResults: [
        .fetchShareParticipants(
          .init(
            perShareParticipantResults: [
              .init(
                lookupInfo: lookupInfo1,
                result: .success(CKShare.Participant.mock)
              ),
              .init(
                lookupInfo: lookupInfo2,
                result: .success(CKShare.Participant.mock)
              )
            ],
            fetchShareParticipantsResult: .init(result: .failure(CKError(CKError.Code.networkFailure)))
          )
        )
      ]
    )
    
    let containerAPI = CKContainerAPI(mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.fetchShareParticipants(with: [lookupInfo1, lookupInfo2], qualityOfService: .default).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
  }
  
  func test_accept_shares_success() async {
    let mockContainer = ReplayingMockCKContainer(
      operationResults: [
        .acceptShares(
          .init(
            perShareResults: [
              .init(metadata: CKShare.Metadata.mock, result: .success(CKShare.mock)),
              .init(metadata: CKShare.Metadata.mock, result: .success(CKShare.mock))
            ],
            acceptSharesResult: .init(
              result: .success(())
            )
          )
        )
      ]
    )
    
    let containerAPI = CKContainerAPI(mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    let shares = try! await containerAPI.acceptShares(with: [CKShare.Metadata.mock, CKShare.Metadata.mock], qualityOfService: .default).get()
    XCTAssertEqual(shares.count, 2)
  }
  
  func test_accept_shares_record_failure() async {
    let mockContainer = ReplayingMockCKContainer(
      operationResults: [
        .acceptShares(
          .init(
            perShareResults: [
              .init(metadata: CKShare.Metadata.mock, result: .failure(CKError(CKError.Code.networkUnavailable))),
              .init(metadata: CKShare.Metadata.mock, result: .success(CKShare.mock))
            ],
            acceptSharesResult: .init(
              result: .success(())
            )
          )
        )
      ]
    )
    
    let containerAPI = CKContainerAPI(mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.acceptShares(with: [CKShare.Metadata.mock, CKShare.Metadata.mock], qualityOfService: .default).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.networkUnavailable)))
    }
  }
  
  func test_accept_shares_result_failure() async {
    let mockContainer = ReplayingMockCKContainer(
      operationResults: [
        .acceptShares(
          .init(
            perShareResults: [
              .init(metadata: CKShare.Metadata.mock, result: .success(CKShare.mock)),
              .init(metadata: CKShare.Metadata.mock, result: .success(CKShare.mock))
            ],
            acceptSharesResult: .init(
              result: .failure(CKError(CKError.Code.badContainer))
            )
          )
        )
      ]
    )
    
    let containerAPI = CKContainerAPI(mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.acceptShares(with: [CKShare.Metadata.mock, CKShare.Metadata.mock], qualityOfService: .default).get()
    } catch {
      XCTAssertEqual(error as! CKRecordError, CKRecordError(from: CKError(CKError.Code.badContainer)))
    }
  }
}
