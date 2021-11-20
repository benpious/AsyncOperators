/// Use to convert a Task into an `AsyncSequence`.
public struct AsyncSequenceOfOne<Element, Error>: AsyncSequence where Error: Swift.Error {
    
    let task: Task<Element, Error>
    
    public init(task: Task<Element, Error>) {
        self.task = task
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        let task: Task<Element, Error>
        
        public func next() async throws -> Element? {
            try await task.value
        }
        
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(task: task)
    }
    
}

public struct JustError<Element, Error>: AsyncSequence where Error: Swift.Error {
    
    public init(_ error: Error) {
        self.error = error
    }
    
    let error: Error
    
    public func makeAsyncIterator() -> Iterator {
        .init(error: error)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        let error: Error
        
        public func next() async throws -> Element? {
            throw error
        }
        
    }
    
}

/// A sequence of one value: an `Element` or `Error`.
public struct Just<Element>: AsyncSequence {
    
    init(_ value: Element) {
        self.value = value
    }
        
    var value: Element
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(value: value)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        let value: Element
        var hasSent = false
        
        public mutating func next() async -> Element? {
            if hasSent {
                return nil
            } else {
                hasSent = true
                return value
            }
        }
    }
    
}

