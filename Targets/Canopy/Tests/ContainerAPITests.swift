@testable import Canopy
import CanopyTestTools
import CloudKit
import Foundation
import Testing

@Suite struct ContainerAPITests {
  @Test func test_userRecordID_success() async {
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
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 0))
    let result = try? await containerAPI.userRecordID.get()
    #expect(result == recordID)
  }
  
  @Test func test_userRecordID_failure() async {
    let ckError = CKError(CKError.Code.networkUnavailable)
    let container = ReplayingMockCKContainer(
      operationResults: [
        .userRecordID(.init(userRecordID: nil, error: ckError))
      ]
    )
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.userRecordID.get()
    } catch {
      #expect(error == CKRecordError(from: ckError))
    }
  }
  
  @Test func test_accountStatus_success() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil))
      ]
    )
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 0))
    let result = try? await containerAPI.accountStatus.get()
    #expect(result == .available)
  }
  
  @Test func test_accountStatus_success_multiple_requests() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil))
      ]
    )
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 0))
    let result = try! await containerAPI.accountStatus.get()
    #expect(result == .available)
    
    // Try more requests, so there are more requests than inputs.
    // mock accountStatus API returns the last status without dequeueing it.
    let result2 = try! await containerAPI.accountStatus.get()
    let result3 = try! await containerAPI.accountStatus.get()
    #expect(result2 == .available)
    #expect(result3 == .available)
  }
  
  @Test func test_accountStatus_failure() async {
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
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.accountStatus.get()
    } catch {
      #expect(error == .ckAccountError("The operation couldn’t be completed. (CKErrorDomain error 36.)", CKError.Code.accountTemporarilyUnavailable.rawValue))
    }
  }
  
  @Test func test_accountStatus_stream() async {
    // This test was sometimes failing. The cause was that the account statuses were sometimes delivered out of order.
    // https://github.com/tact/Canopy/issues/6
    // Got a repeatable scenario by running this as a stress test with many iterations.
    // A fix is to delay the status change notifications in the mock stream by a small amount.
    // Not great because it makes the tests slower. Better solution would be to somehow ensure
    // that the status deliveries are never out-of-order in ReplayingMockCKContainer.
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil)),
        .accountStatus(.init(status: .noAccount, error: nil)),
        .accountStatus(.init(status: .couldNotDetermine, error: CKError(CKError.Code.accountTemporarilyUnavailable))),
        .accountStatus(.init(status: .restricted, error: nil))
      ]
    )
    
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 3))
    var statuses: [CKAccountStatus] = []
    let stream = try! await containerAPI.accountStatusStream.get()
    for await status in stream {
      statuses.append(status)
      if statuses.count == 3 { break }
    }
    let expectedStatuses: [CKAccountStatus] = [.available, .noAccount, .restricted]
    #expect(statuses == expectedStatuses)
  }
  
  @Test func test_accountStatus_twoStreams() async {
    let container = ReplayingMockCKContainer(
      operationResults: [
        .accountStatus(.init(status: .available, error: nil)),
        .accountStatus(.init(status: .noAccount, error: nil)),
        .accountStatus(.init(status: .restricted, error: nil))
      ]
    )
    
    let containerAPI = CKContainerAPI(container: container, accountChangedSequence: .mock(elementsToProduce: 2))
    var statuses1: [CKAccountStatus] = []
    
    let stream1 = try! await containerAPI.accountStatusStream.get()
    
    do {
      let _ = try await containerAPI.accountStatusStream.get()
    } catch {
      #expect(error == .onlyOneAccountStatusStreamSupported)
    }
    
    for await status in stream1 {
      statuses1.append(status)
      if statuses1.count == 3 { break }
    }
    
    let expected: [CKAccountStatus] = [.available, .noAccount, .restricted]
    #expect(statuses1 == expected)
  }
  
  @Test func test_fetch_share_participants_success() async {
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
    
    let containerAPI = CKContainerAPI(container: mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    let participants = try? await containerAPI.fetchShareParticipants(with: [lookupInfo1, lookupInfo2]).get()
    #expect(participants == [CKShare.Participant.mock, CKShare.Participant.mock])
  }
  
  @Test func test_fetch_share_participants_record_error() async {
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
    
    let containerAPI = CKContainerAPI(container: mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.fetchShareParticipants(with: [lookupInfo1, lookupInfo2]).get()
    } catch {
      #expect(error == CKRecordError(from: CKError(CKError.Code.badContainer)))
    }
  }
  
  @Test func test_fetch_share_participants_result_error() async {
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
    
    let containerAPI = CKContainerAPI(container: mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.fetchShareParticipants(with: [lookupInfo1, lookupInfo2]).get()
    } catch {
      #expect(error == CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
  }
  
  @Test func test_accept_shares_success() async {
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
    
    let containerAPI = CKContainerAPI(container: mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    let shares = try! await containerAPI.acceptShares(with: [CKShare.Metadata.mock, CKShare.Metadata.mock]).get()
    #expect(shares.count == 2)
  }
  
  @Test func test_accept_shares_record_failure() async {
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
    
    let containerAPI = CKContainerAPI(container: mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.acceptShares(with: [CKShare.Metadata.mock, CKShare.Metadata.mock]).get()
    } catch {
      #expect(error == CKRecordError(from: CKError(CKError.Code.networkUnavailable)))
    }
  }
  
  @Test func test_accept_shares_result_failure() async {
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
    
    let containerAPI = CKContainerAPI(container: mockContainer, accountChangedSequence: .mock(elementsToProduce: 0))
    do {
      let _ = try await containerAPI.acceptShares(with: [CKShare.Metadata.mock, CKShare.Metadata.mock]).get()
    } catch {
      #expect(error == CKRecordError(from: CKError(CKError.Code.badContainer)))
    }
  }
}
