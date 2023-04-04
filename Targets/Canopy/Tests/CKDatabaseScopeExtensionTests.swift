@testable import Canopy
import CloudKit
import XCTest

final class CKDatabaseScopeExtensionTests: XCTestCase {
  func test_private_scope() {
    XCTAssertEqual(CKDatabase.Scope.private.asString, "private")
  }
  
  func test_shared_scope() {
    XCTAssertEqual(CKDatabase.Scope.shared.asString, "shared")
  }

  func test_public_scope() {
    XCTAssertEqual(CKDatabase.Scope.public.asString, "public")
  }
}
