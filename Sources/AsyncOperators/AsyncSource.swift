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
            var index = 0
            while index < observers.count {
                let observer = observers[index]
                if let observer = observer.iterator {
                    observer.value = value
                    index += 1
                } else {
                    observers.remove(at: index)
                }
            }
        }
    }
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = Element
    
    private var observers: [WeakRef] = []
    
    private struct WeakRef {
        weak var iterator: Iterator?
    }
    
    public func makeAsyncIterator() -> Iterator {
        let iterator = Iterator()
        observers.append(.init(iterator: iterator))
        iterator.value = value
        return iterator
    }
    
    public final class Iterator: AsyncIteratorProtocol {
        
        var value: Element?
        
        public func next() async throws -> Element? {
            while value == nil {
                
            }
            defer {
                value = nil
            }
            return value
        }
        
    }
    
}
