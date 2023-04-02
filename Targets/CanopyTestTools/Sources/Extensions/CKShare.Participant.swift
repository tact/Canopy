import CloudKit

public extension CKShare.Participant {
  /// Mock CKShare.Participant that unarchives to a real CKShare.Participant value.
  ///
  /// We can use this participant as a mock value in our tests, if there’s no need to match it to a real user in a current real container.
  static var mock: CKShare.Participant {
    let mockParticipantBase64 = "YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMSAAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVR" +
      "yb290gAGvEBYLDDM0R01OWFlaYGNnd3t/io6SlZaZVSRudWxs3xAVDQ4PEBESExQVFhcYGRobHB0eHyAhIiMiJCUjJCcoJCojKCQtKCokKCQoWlBlcm1pc3Npb25fEBhPcm" +
      "lnaW5hbEFjY2VwdGFuY2VTdGF0dXNfEBJPcmlnaW5hbFBlcm1pc3Npb25fEBd3YW50c05ld0ludml0YXRpb25Ub2tlblYkY2xhc3NfEBxtdXRhYmxlSW52aXRhdGlvblRva" +
      "2VuU3RhdHVzXxAdaXNBbm9ueW1vdXNJbnZpdGVkUGFydGljaXBhbnRdUGFydGljaXBhbnRJRFlJbnZpdGVySURfEBBDcmVhdGVkSW5Qcm9jZXNzVFR5cGVfEBBBY2NlcHRh" +
      "bmNlU3RhdHVzXxAXUHJvdGVjdGlvbkluZm9QdWJsaWNLZXleSXNPcmdBZG1pblVzZXJcVXNlcklkZW50aXR5XxAPSW52aXRhdGlvblRva2VuXxAXT3JpZ2luYWxQYXJ0aWN" +
      "pcGFudFR5cGVfEBFBY2NlcHRlZEluUHJvY2Vzc15Qcm90ZWN0aW9uSW5mb11Jc0N1cnJlbnRVc2VyXxAVRW5jcnlwdGVkUGVyc29uYWxJbmZvEAIQAQiAFQiAAoAACBADgA" +
      "AIgAOAAAiAAAiAAF8QJEVFQjlCRkY0LTdFNDgtNEY5Ni04NTFDLThFQjcwMEVFRTJGNdo1Njc4OSEROjs8JD4/QEEoQyhFRlhJc0NhY2hlZF5Qcm90ZWN0aW9uRGF0YVxVc" +
      "2VyUmVjb3JkSURfEBBIYXNJQ2xvdWRBY2NvdW50Xk5hbWVDb21wb25lbnRzXxART09OUHJvdGVjdGlvbkRhdGFaTG9va3VwSW5mb18QEkNvbnRhY3RJZGVudGlmaWVycwiA" +
      "E4AECYALgACAFIAAgA+AEdMRSElKS0xaUmVjb3JkTmFtZVZab25lSUSACoAFgAZfECFfMmI3ZTI2ODgxY2ZmNjdhOTYzNjkxYjRkNTdjNzNlZmXVT1BRUhFTKFVWV18QEGR" +
      "hdGFiYXNlU2NvcGVLZXlfEBFhbm9ueW1vdXNDS1VzZXJJRFlvd25lck5hbWVYWm9uZU5hbWUQAIAAgAiAB4AJXF9kZWZhdWx0Wm9uZV8QEF9fZGVmYXVsdE93bmVyX1/SW1" +
      "xdXlokY2xhc3NuYW1lWCRjbGFzc2VzXkNLUmVjb3JkWm9uZUlEol1fWE5TT2JqZWN00ltcYWJaQ0tSZWNvcmRJRKJhX9IRZGVmXxAYTlMubmFtZUNvbXBvbmVudHNQcml2Y" +
      "XRlgA6ADNhoEWlqa2xtbihwKCgoKCgoXU5TLm1pZGRsZU5hbWVdTlMuZmFtaWx5TmFtZVtOUy5uaWNrbmFtZVxOUy5naXZlbk5hbWVdTlMubmFtZVByZWZpeF1OUy5uYW1l" +
      "U3VmZml4XxAZTlMucGhvbmV0aWNSZXByZXNlbnRhdGlvboAAgA2AAIAAgACAAIAAgADSW1x4eV8QG19OU1BlcnNvbk5hbWVDb21wb25lbnRzRGF0YaJ6X18QG19OU1BlcnN" +
      "vbk5hbWVDb21wb25lbnRzRGF0YdJbXHx9XxAWTlNQZXJzb25OYW1lQ29tcG9uZW50c6J+X18QFk5TUGVyc29uTmFtZUNvbXBvbmVudHPWEYCBgiGDhCg/JCgoW1Bob25lTn" +
      "VtYmVyWFJlY29yZElEXlJlcG9ydHNNaXNzaW5nXEVtYWlsQWRkcmVzc4AQgACABAiAAIAA0ltci4xfEBhDS1VzZXJJZGVudGl0eUxvb2t1cEluZm+ijV9fEBhDS1VzZXJJZ" +
      "GVudGl0eUxvb2t1cEluZm/SjxGQkVpOUy5vYmplY3RzoIAS0ltck5RXTlNBcnJheaKTX08QiTCBhgRBBBHgsvEOwV1neQOxZapFRBUwdhrvSphuMPHNEw7VAYKZ17VBtLBX" +
      "mo7uMEwv11cArv9oBTHbo2k7iZs2YLQKPFAEQQRw9jLjKISyLC9nPYZoPizSt7ViqriLjWkKB4hjPDqYU+0aUk5KJEkaccnrjlx+6j9yNWjjOeKGktIINS3UZZOu0ltcl5h" +
      "eQ0tVc2VySWRlbnRpdHmil1/SW1yam18QEkNLU2hhcmVQYXJ0aWNpcGFudKKaXwAIABEAGgAkACkAMgA3AEkATABRAFMAbAByAJ8AqgDFANoA9AD7ARoBOgFIAVIBZQFqAX" +
      "0BlwGmAbMBxQHfAfMCAgIQAigCKgIsAi0CLwIwAjICNAI1AjcCOQI6AjwCPgI/AkECQgJEAmsCgAKJApgCpQK4AscC2wLmAvsC/AL+AwADAQMDAwUDBwMJAwsDDQMUAx8DJ" +
      "gMoAyoDLANQA1sDbgOCA4wDlQOXA5kDmwOdA58DrAO/A8QDzwPYA+cD6gPzA/gEAwQGBAsEJgQoBCoEOwRJBFcEYwRwBH4EjASoBKoErASuBLAEsgS0BLYEuAS9BNsE3gT8" +
      "BQEFGgUdBTYFQwVPBVgFZwV0BXYFeAV6BXsFfQV/BYQFnwWiBb0FwgXNBc4F0AXVBd0F4AZsBnEGgAaDBogGnQAAAAAAAAIBAAAAAAAAAJwAAAAAAAAAAAAAAAAAAAag"
    
    let mockParticipantData = Data(base64Encoded: mockParticipantBase64)!
    do {
      guard let participant = try NSKeyedUnarchiver.unarchivedObject(
        ofClass: CKShare.Participant.self,
        from: mockParticipantData
      ) else {
        fatalError("Could not unarchive the mock participant")
      }
      return participant
    } catch {
      fatalError("Could not unarchive the mock participant: \(error)")
    }
  }
}
