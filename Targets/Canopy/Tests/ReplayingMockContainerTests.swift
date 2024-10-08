import CanopyTestTools
import CanopyTypes
import CloudKit
import XCTest

final class ReplayingMockContainerTests: XCTestCase {
  func test_userRecordID_success() async {
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
    XCTAssertEqual(result.recordName, "myRecordId")
  }
  
  func test_userRecordID_error() async {
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
      XCTAssertEqual(error, CKRecordError(from: CKError(CKError.Code.networkFailure)))
    }
  }
  
  func test_accountStatus_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .accountStatus(.init(status: .couldNotDetermine, error: nil))
      ]
    )
    
    let result = try! await mockContainer.accountStatus.get()
    XCTAssertEqual(result, .couldNotDetermine)
  }
  
  func test_accountStatus_error() async {
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
      XCTAssertEqual(error.code, CKError.Code.badContainer.rawValue)
    }
  }
  
  func test_accountStatusStream_success() async {
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
    XCTAssertEqual(statuses, [.available, .noAccount])
  }
  
  func test_accountStatusStream_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .accountStatusStream(.init(statuses: [], error: .onlyOneAccountStatusStreamSupported))
      ]
    )
    do {
      let _ = try await mockContainer.accountStatusStream.get()
    } catch {
      XCTAssertEqual(error, .onlyOneAccountStatusStreamSupported)
    }
  }
  
  func test_acceptShares_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .acceptShares(.init(result: .success([CKShare.mock, CKShare.mock_owned_by_current_user])))
      ]
    )
    let result = try! await mockContainer.acceptShares(with: []).get()
    XCTAssertEqual(result.count, 2)
  }
  
  func test_acceptShares_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .acceptShares(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
      ]
    )
    do {
      let _ = try await mockContainer.acceptShares(with: []).get()
    } catch {
      XCTAssertEqual(error.code, CKError.Code.networkFailure.rawValue)
    }
  }
  
  func test_fetchShareParticipants_success() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .fetchShareParticipants(.init(result: .success([CKShare.Participant.mock, CKShare.Participant.mock])))
      ]
    )
    let result = try! await mockContainer.fetchShareParticipants(with: []).get()
    XCTAssertEqual(result.count, 2)
  }
  
  func test_fetchShareParticipants_error() async {
    let mockContainer = ReplayingMockContainer(
      operationResults: [
        .fetchShareParticipants(.init(result: .failure(.init(from: CKError(CKError.Code.networkFailure)))))
      ]
    )
    do {
      let _ = try await mockContainer.fetchShareParticipants(with: []).get()
    } catch {
      XCTAssertEqual(error.code, CKError.Code.networkFailure.rawValue)
    }
  }
}
