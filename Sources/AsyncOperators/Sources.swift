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

/// A sequence with one element: an error.
public struct JustError<Element, Error>: Sendable, AsyncSequence where Error: Swift.Error {
    
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
public struct Just<Element>: Sendable, AsyncSequence where Element: Sendable {
    
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

