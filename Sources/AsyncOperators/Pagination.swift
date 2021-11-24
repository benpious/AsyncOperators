/// A type that can be paginated.
///
/// Typically the result of a network request.
public protocol Paginated {
    
    /// Represents context used to generate the next element in the sequence. 
    associatedtype PaginationToken
    
    /// The token showing what the next values should be.
    var paginationToken: PaginationToken { get }
    
}

/// Represents a series of values which are paginated, in other words:
///  the output of the prior value is fed forwards to generate the next value.
public struct Pagination<T>: AsyncSequence where T: Paginated {
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = T
    
    var getter: (T.PaginationToken?) async throws -> T?
        
    public func makeAsyncIterator() -> Iterator {
        Iterator(getter: getter)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        var paginationToken: AsyncSource<T.PaginationToken> = .init()
        var getter: (T.PaginationToken?) async throws -> T?
        var hasSentOnce = false
        
        public func next() async throws -> T? {
            if hasSentOnce {
                for try await token in paginationToken {
                    let result = try await getter(token)
                    paginationToken.value = result?.paginationToken
                    return result
                }
                return nil
            } else {
                let result = try await getter(nil)
                paginationToken.value = result?.paginationToken
                return result
            }
        }
        
    }
    
}

