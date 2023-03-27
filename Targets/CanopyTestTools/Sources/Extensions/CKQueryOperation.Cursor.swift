import CloudKit

public extension CKQueryOperation.Cursor {
  
  /// Mock CKQueryOperation.Cursor that unarchives to a real cursor value.
  ///
  /// We can use this cursor as a mock value in our tests, if there’s no need to match it to a real query.
  static var mock: CKQueryOperation.Cursor {
  
    /// Archived data representing a real CKQueryOperation.Cursor that we use as a mock value.
    let mockCursorBase64 = "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05" +
"TS2V5ZWRBcmNoaXZlctEICVRyb290gAGoCwwTFB4fICZVJG51bGzTDQ4PEBESVlpvbmVJRFYkY2xhc3" +
"NaQ3Vyc29yRGF0YYADgAeAAk8RAXUKiwEKBgoEQ2hhdBKAAQoOCgxfX19jcmVhdGVkQnkSbAgFSmgIA" +
"hJkCiUKIV9iZGY2YWEyYjUyZDBhYjM0OWEyYzEwYzI1OTg0Njc3MRABEjsKEAoMX2RlZmF1bHRab25l" +
"EAYSJQohX2JkZjZhYTJiNTJkMGFiMzQ5YTJjMTBjMjU5ODQ2NzcxEAcYASABEuQBQW9FL2hRRnBRMnh" +
"2ZFdRdVkyOXRMbXAxYzNSMFlXTjBMbFJoWTNRa01TUnpZVzVrWW05NEpEQTVNak16WXpaaExUUXdObV" +
"V0TkdFMVl5MWlZek0zTFRaa01tWTJaREF3TXpKaVlTRXhaRGxpTWpRMk1DMWlNek0zTFRSbE4yUXRPR" +
"0psWVMwMk56VXhPVE00T1dWaU16RmtNalUzTnpRMUlVMXFUWGhSYW1NMVRYcFJkRkpVV1RGU1V6QXdU" +
"bFZTUlV4VWFFVk9lbFYwVFhwU1EwMVZVa1pTVkVsNFRsUlNSUT091RUWFxgOGRobHB1fEBBkYXRhYmF" +
"zZVNjb3BlS2V5XxARYW5vbnltb3VzQ0tVc2VySURZb3duZXJOYW1lWFpvbmVOYW1lEACAAIAFgASABl" +
"VDaGF0c18QEF9fZGVmYXVsdE93bmVyX1/SISIjJFokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkW" +
"m9uZUlEoiMlWE5TT2JqZWN00iEiJyhdQ0tRdWVyeUN1cnNvcqInJQAIABEAGgAkACkAMgA3AEkATABR" +
"AFMAXABiAGkAcAB3AIIAhACGAIgCAQIMAh8CMwI9AkYCSAJKAkwCTgJQAlYCaQJuAnkCggKRApQCnQK" +
"iArAAAAAAAAACAQAAAAAAAAApAAAAAAAAAAAAAAAAAAACsw=="
    
    let mockCursorData = Data(base64Encoded: mockCursorBase64)!
    do {
      guard let cursor = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKQueryOperation.Cursor.self,
        from: mockCursorData
      ) else {
        fatalError("Could not unarchive the mock cursor")
      }
      return cursor
    } catch {
      fatalError("Could not unarchive the mock cursor: \(error)")
    }
  }
}
