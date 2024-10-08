import Canopy
import CloudKit
import Foundation

public actor ReplayingMockCKContainer {
  public enum OperationResult: Codable, Sendable {
    case userRecordID(UserRecordIDResult)
    case accountStatus(AccountStatusResult)
    case fetchShareParticipants(FetchShareParticipantsOperationResult)
    case acceptShares(AcceptSharesOperationResult)
  }

  // Since testing showed that results can be requested in nondeterministic order,
  // we bucket and store them per type, so they can be dequeued independently.
  
  private var userRecordIDResults: [OperationResult] = []
  private var accountStatusResults: [OperationResult] = []
  private var fetchShareParticipantsResults: [OperationResult] = []
  private var acceptSharesResults: [OperationResult] = []
  
  /// How many operations were tun in this database.
  public private(set) var operationsRun = 0
  
  public init(
    operationResults: [OperationResult] = []
  ) {
    for result in operationResults {
      switch result {
      case .userRecordID: userRecordIDResults.append(result)
      case .accountStatus: accountStatusResults.append(result)
      case .fetchShareParticipants: fetchShareParticipantsResults.append(result)
      case .acceptShares: acceptSharesResults.append(result)
      }
    }
  }
  
  func privateFetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
    guard let operationResult = userRecordIDResults.first, case let .userRecordID(result) = operationResult else {
      fatalError("Asked to fetch user record ID without an available result. Likely a logic error on caller side")
    }
    userRecordIDResults.removeFirst()
    operationsRun += 1
    
    if let error = result.recordError {
      completionHandler(nil, error.ckError)
    } else {
      completionHandler(result.userRecordIDArchive!.recordIDs.first!, nil)
    }
  }
  
  func privateAccountStatus(completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
    guard let operationResult = accountStatusResults.first, case let .accountStatus(result) = operationResult else {
      fatalError("Asked for account status without an available result. Likely a logic error on caller side")
    }
    if accountStatusResults.count > 1 {
      // Account status behaves differently from the other mocks.
      // The other mocks always dequeue the result, resulting in an error
      // if you do more requests than you have results waiting in the queue.
      // accountStatus keeps replaying the last one without dequeueing it.
      accountStatusResults.removeFirst()
    }
    operationsRun += 1

    if let error = result.canopyError {
      completionHandler(.couldNotDetermine, error.ckError)
    } else {
      if let accountStatus = CKAccountStatus(rawValue: result.statusValue) {
        completionHandler(accountStatus, nil)
      } else {
        fatalError("Could not recreate CKAccountStatus from value \(result.statusValue)")
      }
    }
  }
  
  func privateAdd(_ operation: CKOperation) async {
    if let fetchShareParticipantsOperation = operation as? CKFetchShareParticipantsOperation,
       let operationResult = fetchShareParticipantsResults.first,
       case let .fetchShareParticipants(result) = operationResult
    {
      fetchShareParticipantsResults.removeFirst()
      operationsRun += 1
      runFetchShareParticipantsOperation(fetchShareParticipantsOperation, operationResult: result)
    } else if let acceptSharesOperation = operation as? CKAcceptSharesOperation,
              let operationResult = acceptSharesResults.first,
              case let .acceptShares(result) = operationResult
    {
      acceptSharesResults.removeFirst()
      operationsRun += 1
      runAcceptSharesOperation(acceptSharesOperation, operationResult: result)
    } else {
      fatalError("No result or incorrect result type available for operation: \(operation)")
    }
  }
}

extension ReplayingMockCKContainer: CKContainerType {
  public nonisolated func accountStatus(completionHandler: @escaping (CKAccountStatus, Error?) -> Void) {
    Task {
      await privateAccountStatus(completionHandler: completionHandler)
    }
  }
  
  public nonisolated func fetchUserRecordID(completionHandler: @escaping (CKRecord.ID?, Error?) -> Void) {
    Task {
      await privateFetchUserRecordID(completionHandler: completionHandler)
    }
  }
  
  public nonisolated func add(_ operation: CKOperation) {
    Task {
      await privateAdd(operation)
    }
  }
}
