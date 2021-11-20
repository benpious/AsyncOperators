/// Turns an Array into an `AsyncSequence`.
///
/// This is very useful for testing. 
public struct AsyncArray<Element>: AsyncSequence {
    
    var base: [Element]
    
    /// Initializer.
    public init(_ base: [Element]) {
        self.base = base
    }
    
    /// Initializer.
    public init(_ base: Element...) {
        self.base = base
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        public mutating func next() async -> Element? {
            base.next()
        }
        
        var base: Array<Element>.Iterator
        
    }
    
}
