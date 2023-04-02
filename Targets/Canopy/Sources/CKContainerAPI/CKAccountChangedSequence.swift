import Foundation

struct CKAccountChangedSequence: AsyncSequence {
  public typealias Element = Void

  enum Kind {
    case mock(Int)
    case live(NotificationCenter.Notifications)
  }
  
  let kind: Kind
  
  public static var live: CKAccountChangedSequence {
    .init(kind: .live(NotificationCenter.default.notifications(named: .CKAccountChanged)))
  }
  
  public static func mock(elementsToProduce: Int) -> CKAccountChangedSequence {
    .init(kind: .mock(elementsToProduce))
  }
  
  private init(kind: Kind) {
    self.kind = kind
  }
  
  public struct AsyncIterator: AsyncIteratorProtocol {
    let kind: Kind
    var mockElementsToProduce: Int = 0
    
    init(kind: Kind) {
      self.kind = kind
      if case let .mock(elementsToProduce) = kind {
        self.mockElementsToProduce = elementsToProduce
      }
    }
    
    public mutating func next() async -> Void? {
      switch kind {
      case .mock:
        guard mockElementsToProduce > 0 else {
          return nil
        }
        mockElementsToProduce -= 1
        return ()
      case let .live(notifications):
        let _ = await notifications.first(where: { _ in true })
        return ()
      }
    }
  }

  public func makeAsyncIterator() -> AsyncIterator {
    AsyncIterator(kind: kind)
  }
}
