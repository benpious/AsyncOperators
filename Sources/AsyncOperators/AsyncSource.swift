/// Represents a piece of data which changes over time.
///
/// Whenever `value` is set, a new element is appended to the sequence.
///
/// - Note: This sequence never completes.
public final class AsyncSource<Element>: AsyncSequence {
    
    /// Initializer.
    public init(_ start: Element? = nil) {
        value = start
    }
    
    /// The element represented by the callee.
    ///
    /// Set this to cause a new value to be added to the callee's sequence.
    public var value: Element? = nil {
        didSet {
            if let value = value {
                for observer in observers {
                    observer.continuation.yield(value)
                }
            }
        }
    }
    
    public typealias Element = Element
    
    private var observers: [Observer] = []
    
    private struct Observer {
        var continuation: AsyncThrowingStream<Element, Error>.Continuation
    }
    
    public func makeAsyncIterator() -> AsyncThrowingStream<Element, Error>.AsyncIterator {
        AsyncThrowingStream<Element, Error> { continuation in
            self.observers.append(.init(continuation: continuation))
            if let value = value {
                continuation.yield(value)
            }
        }
        .makeAsyncIterator()
    }
        
}

@propertyWrapper
public struct Streaming<Wrapped> {
    
    public init(wrappedValue: Wrapped) {
        self.wrappedValue = wrappedValue
    }
    
    let source = AsyncSource<Wrapped>(nil)
    
    public var wrappedValue: Wrapped {
        didSet {
            source.value = wrappedValue
        }
    }
    
    public var projectedValue: AsyncSource<Wrapped> {
        source
    }
    
}
