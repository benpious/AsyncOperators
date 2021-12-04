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
                for observer in singleObservers {
                    observer.resume(returning: value)
                }
                singleObservers = []
                for observer in observers {
                    observer.continuation.yield(value)
                }
            }
        }
    }
    
    var next: Element {
        get async {
            await withCheckedContinuation { continuation in
                singleObservers.append(continuation)
            }
        }
    }
    
    public typealias Element = Element
    
    private var observers: [Observer] = []
    private var singleObservers: [CheckedContinuation<Element, Never>] = []
        
    private struct Observer {
        var continuation: AsyncStream<Element>.Continuation
    }
    
    public func makeAsyncIterator() -> AsyncStream<Element>.AsyncIterator {
        AsyncStream<Element> { continuation in
            self.observers.append(.init(continuation: continuation))
            if let value = value {
                continuation.yield(value)
            }
        }
        .makeAsyncIterator()
    }
    
}

/// Streams values when set.
///
/// You get access to the stream by using the projected value
/// of the property wrapper.
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
