import Canopy
import CanopyTestTools
import CloudKit
import Testing

@Suite struct ReplayingMockContainerTests {
  @Test func test_userRecordID_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .userRecordID(
          .init(
            userRecordID: CKRecord.ID(recordName: "myRecordId")
          )
        )
      ]
    )
    
    let result = try! await mockContainer.userRecordID.get()!
    #expect(result.recordName == "myRecordId")
  }
  
  @Test func test_userRecordID_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .userRecordID(
          .init(
            error: CKRecordError(from: CKError(CKError.Code.networkFailure))
          )
        )
      ]
    )
    
    do {
      let _ = try await mockContainer.userRecordID.get()
    } catch {
      #expect(error == CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
  }
  
  @Test func test_accountStatus_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .accountStatus(.init(status: .couldNotDetermine, error: nil))
      ]
    )
    
    let result = try! await mockContainer.accountStatus.get()
    #expect(result == .couldNotDetermine)
  }
  
  @Test func test_accountStatus_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .accountStatus(
          .init(
            status: .couldNotDetermine,
            error: .ckAccountError("some account error", CKError.Code.badContainer.rawValue)
          )
        )
      ]
    )
    
    do {
      let _ = try await mockContainer.accountStatus.get()
    } catch {
      #expect(error.code == CKError.Code.badContainer.rawValue)
    }
  }
  
  @Test func test_accountStatusStream_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .accountStatusStream(.init(statuses: [.available, .noAccount, .couldNotDetermine], error: nil))
      ]
    )
    
    var statuses: [CKAccountStatus] = []
    let accountStatusStream = try! await mockContainer.accountStatusStream.get()
    for await status in accountStatusStream.prefix(2) {
      statuses.append(status)
    }
    #expect(statuses == [.available, .noAccount])
  }
  
  @Test func test_accountStatusStream_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .accountStatusStream(.init(statuses: [], error: .onlyOneAccountStatusStreamSupported))
      ]
    )
    do {
      let _ = try await mockContainer.accountStatusStream.get()
    } catch {
      #expect(error == .onlyOneAccountStatusStreamSupported)
    }
  }
  
  @Test func test_acceptShares_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .acceptShares(.init(result: .success([CKShare.mock, CKShare.mock_owned_by_current_user])))
      ]
    )
    let result = try! await mockContainer.acceptShares(with: []).get()
    #expect(result.count == 2)
  }
  
  @Test func test_acceptShares_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .acceptShares(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
      ]
    )
    do {
      let _ = try await mockContainer.acceptShares(with: []).get()
    } catch {
      #expect(error.code == CKError.Code.networkFailure.rawValue)
    }
  }
  
  @Test func test_fetchShareParticipants_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .fetchShareParticipants(.init(result: .success([CKShare.Participant.mock, CKShare.Participant.mock])))
      ]
    )
    let result = try! await mockContainer.fetchShareParticipants(with: []).get()
    #expect(result.count == 2)
  }
  
  @Test func test_fetchShareParticipants_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .fetchShareParticipants(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
      ]
    )
    do {
      let _ = try await mockContainer.fetchShareParticipants(with: []).get()
    } catch {
      #expect(error.code == CKError.Code.networkFailure.rawValue)
    }
  }
}
