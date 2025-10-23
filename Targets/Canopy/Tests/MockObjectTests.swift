@testable import Canopy
import CanopyTestTools
import CloudKit
import Foundation
import Testing

/// Test the validity mock objects provided as part of the test tools.
@Suite struct MockObjectTests {
  @Test func test_mock_share_owned_by_another_user() {
    let share = CKShare.mock
    #expect(share.participants.count == 2)
  }
  
  @Test func test_mock_share_owned_by_current_user() {
    let share = CKShare.mock_owned_by_current_user
    #expect(share.participants.count == 3)
  }
}
