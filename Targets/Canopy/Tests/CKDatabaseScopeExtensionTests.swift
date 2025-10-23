@testable import Canopy
import CloudKit
import Testing

@Suite struct CKDatabaseScopeExtensionTests {
  @Test func test_private_scope() {
    #expect(CKDatabase.Scope.private.asString == "private")
  }
  
  @Test func test_shared_scope() {
    #expect(CKDatabase.Scope.shared.asString == "shared")
  }

  @Test func test_public_scope() {
    #expect(CKDatabase.Scope.public.asString == "public")
  }
}
