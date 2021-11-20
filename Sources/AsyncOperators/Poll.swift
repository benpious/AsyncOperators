/// A async sequence that appends a new value after some time passes.
///
/// This sequence is "cold" in the sense that it does not start working
/// until you start enumerating it. 
///
/// - Note: this sequence never terminates.
public struct Poll: AsyncSequence {
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = ()
    
    public struct Iterator: AsyncIteratorProtocol {
        
        let duration: UInt64
        
        public func next() async -> ()? {
            guard !Task.isCancelled else {
                return nil
            }
            return await Task.sleep(duration)
        }
        
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(duration: duration)
    }
    
    let duration: UInt64
    
    public init(nanoseconds: UInt64) {
        self.duration = nanoseconds
    }
    
}
