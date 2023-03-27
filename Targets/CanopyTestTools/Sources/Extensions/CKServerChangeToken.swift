import CloudKit

public extension CKServerChangeToken {
  
  /// Mock CKServerChangeToken that unarchives to a real token value.
  ///
  /// We can use this token as a mock value in our tests, if there’s no need to match it to a real CKDatabase state.
  static var mock: CKServerChangeToken {
    let mockTokenBase64 = "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS" +
"AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGkCwwRElUkbnVsbNINDg8QViRjbGFzc18QD0" +
"NoYW5nZVRva2VuRGF0YYADgAJJAQAAAYYRIGk+0hMUFRZaJGNsYXNzbmFtZVgkY2xhc3Nlc18QE0NL" +
"U2VydmVyQ2hhbmdlVG9rZW6iFRdYTlNPYmplY3QIERokKTI3SUxRU1heY2p8foCKj5qjubwAAAAAAAA" +
"BAQAAAAAAAAAYAAAAAAAAAAAAAAAAAAAAxQ=="
    
    let mockTokenData = Data(base64Encoded: mockTokenBase64)!
    do {
      guard let token = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKServerChangeToken.self,
        from: mockTokenData
      ) else {
        fatalError("Could not unarchive the mock token")
      }
      return token
    } catch {
      fatalError("Could not unarchive the mock token: \(error)")
    }
  }
}
