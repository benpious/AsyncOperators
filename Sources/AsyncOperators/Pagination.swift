//
//  Copyright (c) 2021. Ben Pious
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//


/// An object (typically a network response) that represents just one
/// "page" of an overall result.
public protocol Paginated {
    
    associatedtype PageToken: Equatable, Sendable
    
    /// The property that is used to retrieve the next page of results.
    /// Might be an offset into the value elsewhere.
    var paginationToken: PageToken { get }

    /// Called when the next result is recieved by a `Pagination`.
    ///
    /// The callee is the prior result, and `nextResult` is the current result.
    ///
    ///The return value should typically include the data from the prior result,
    ///
    /// For an array, a correct implementation of this function would
    /// be `self + nextResult`
    func reduce(nextResult: Self) -> Self
    
}

/// Represents a series of values which are paginated, in other words:
///  the output of the prior value is fed forwards to generate the next value.
public struct Pagination<Element>: AsyncSequence where Element: Paginated, Element: Sendable {
    
    /// Initializer.
    ///
    /// - parameter getter: given the next page token (if available), returns
    /// the next element.
    public init(
        getter: @escaping (Element.PageToken?) async throws -> Element?
    ) {
        self.getter = getter
    }
    
    /// Requests the next page using the last page token recieved, if applicable.
    public func requestNextPage() {
        requestSink.value = .init()
    }
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = Element
    
    var getter: (Element.PageToken?) async throws -> Element?
    
    private let paginationToken: AsyncSource<Element.PageToken?> = .init()
    private let requestSink: AsyncSource<Empty> = .init()
            
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            paginationToken: paginationToken,
            requestSink: requestSink
                .withLatestFrom(other: paginationToken)
                .startsWith(.init(.init(), nil))
                .map({ $0.b })
                .makeAsyncIterator(),
            getter: getter
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        
        var paginationToken: AsyncSource<Element.PageToken?>
        var requestSink: AsyncMapSequence<StartsWith<AsyncCompactMapSequence<AsyncThrowingStream<Either<Empty, AsyncSource<Element.PageToken?>.Element>, Error>, Pair<Empty, AsyncSource<Element.PageToken?>.Element>>>, AsyncSource<Element.PageToken?>.Element>.Iterator
        var getter: (Element.PageToken?) async throws -> Element?
        var prior: Element?
        var hasSent = false
        
        public mutating func next() async throws -> Element? {
            if hasSent {
                while let token = try await requestSink.next() {
                    if let nextPartial = try await getter(token) {
                        let next: Element
                        if let prior = prior {
                            next = prior.reduce(nextResult: nextPartial)
                        } else {
                            next = nextPartial
                        }
                        paginationToken.value = next.paginationToken
                        self.prior = next
                        return next
                    } else {
                        return nil
                    }
                }
                return nil
            } else {
                hasSent = true
                let next = try await getter(nil)
                prior = next
                return next
            }
        }
        
    }
    
}

struct Empty: Sendable {
    
}
