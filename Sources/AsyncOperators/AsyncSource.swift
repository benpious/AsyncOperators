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
/// This sequence completes when the AsyncSource is deallocated.
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
                var i = 0
                while i < observers.count {
                    let observer = observers[i]
                    if observer.marker == nil {
                        observers.remove(at: i)
                    } else {
                        observer.continuation.yield(value)
                        i += 1
                    }
                }
            }
        }
    }
            
    private var observers: [Observer] = []
        
    private struct Observer {
        
        var continuation: AsyncStream<Element>.Continuation
        weak var marker: Marker?
        
    }
    
    fileprivate class Marker {
        
    }
    
    public func makeAsyncIterator() -> IteratorWrapper<AsyncStream<Element>.AsyncIterator> {
        let marker = Marker()
        return IteratorWrapper(
            marker: marker,
            base:
                AsyncStream<Element> { continuation in
                    observers.append(.init(
                        continuation: continuation,
                        marker: marker
                        )
                    )
                    if let value = value {
                        continuation.yield(value)
                    }
                }
                .makeAsyncIterator()
        )
    }

    public struct IteratorWrapper<Base>: AsyncIteratorProtocol where Base: AsyncIteratorProtocol, Base.Element == Element {
                
        fileprivate var marker: Marker
        
        var base: Base
        
        var isDead: Bool {
            var marker = self.marker
            return isKnownUniquelyReferenced(&marker)
        }
        
        public mutating func next() async rethrows -> Element? {
            try await base.next()
        }
        
    }
    
    
    deinit {
        for observer in observers {
            observer.continuation.finish()
        }
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

public extension AsyncSource where Element == Void {
    
    func onNext() {
        value = ()
    }
    
}
