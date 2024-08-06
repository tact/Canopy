@testable import Canopy
import CanopyTestTools
import CanopyTypes
import CloudKit
import Foundation
import XCTest

/// Test the validity mock objects provided as part of the test tools.
final class MockObjectTests: XCTestCase {
  func test_mock_share_owned_by_another_user() {
    let share = CKShare.mock
    XCTAssertEqual(share.participants.count, 2)
  }
  
  func test_mock_share_owned_by_current_user() {
    let share = CKShare.mock_owned_by_current_user
    XCTAssertEqual(share.participants.count, 3)
  }
}
