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


public struct DistinctUntilChanged<T>: AsyncSequence where T: AsyncSequence, T.Element: Equatable {
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = T.Element
    
    let base: T
    
    public struct Iterator: AsyncIteratorProtocol {
        
        var iterator: T.AsyncIterator
        var last: T.Element? = nil
        
        public mutating func next() async throws -> T.Element? {
            while let next = try await iterator.next() {
                defer {
                    last = next
                }
                if next != last {
                    return next
                }
            }
            return nil
        }
        
    }
    
    public func makeAsyncIterator() -> Iterator {
        .init(iterator: base.makeAsyncIterator())
    }
    
}

public struct Timeout<A>: AsyncSequence where A: AsyncSequence {
    
    public typealias Element = A.Element
    
    public typealias AsyncIterator = Iterator
    
    public struct Iterator: AsyncIteratorProtocol {
        
        init(
            base: A,
            timeout: Task<Void, Never>
        ) {
            stream = AsyncThrowingStream { continuation in
                Task {
                    do {
                        for try await value in base {
                            continuation.yield(.b(value))
                        }
                    } catch {
                        continuation.finish(throwing: error)
                    }
                }
                Task {
                    await timeout.value
                    continuation.yield(.a(()))
                }
            }
            self.base = base
            self.timeout = timeout
        }
        
        fileprivate let stream: AsyncThrowingStream<Either<Void, Element>, Swift.Error>
        private var gotValue = false
        fileprivate var base: A
        fileprivate let timeout: Task<Void, Never>
        
        public mutating func next() async throws -> A.Element? {
            for try await value in stream {
                switch value {
                case .b(let next):
                    return next
                case .a:
                    if gotValue {
                        continue
                    } else {
                        throw AsyncOpsError(message: "Timed out.")
                    }
                }
            }
            return nil
        }
        
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(
            base: sequence,
            timeout: timeout
        )
    }
    
    private let sequence: A
    private let timeout: Task<Void, Never>
    
    init(_ sequence: A, time: UInt64) {
        self.sequence = sequence
        timeout = Task {
            await Task.sleep(time)
        }
    }
}

public struct StartsWith<A>: AsyncSequence where A: AsyncSequence {

    public typealias Element = A.Element

    public typealias AsyncIterator = Iterator

    public struct Iterator: AsyncIteratorProtocol {

        fileprivate let start: A.Element
        fileprivate var hasStarted = false
        fileprivate var iterator: A.AsyncIterator

        public mutating func next() async throws -> A.Element? {
            if hasStarted == false {
                hasStarted = true
                return start
            } else {
                return try await iterator.next()
            }
        }

    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(start: start, iterator: sequence.makeAsyncIterator())
    }

    let start: A.Element

    let sequence: A

}

fileprivate extension Task {
    
    func map<T>(_ mapper: (Success) throws -> (T)) async throws -> T {
        let initialResult = try await value
        return try mapper(initialResult)
    }
    
}

public enum Either<A, B> {
    case a(A)
    case b(B)
}

public struct CombineLatest1<A, B>: AsyncSequence where A: AsyncSequence, B: AsyncSequence {
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = (A.Element, B.Element)
    
    public struct Iterator: AsyncIteratorProtocol {
        
        var a: A
        var b: B
        var lastA: A.Element?
        var lastB: B.Element?
        
        public mutating func next() async rethrows -> (A.Element, B.Element)? {
            for try await next in concurrently(a, b) {
                switch next {
                case .a(let nextA):
                    lastA = nextA
                case .b(let nextB):
                    lastB = nextB
                }
                if let lastA = lastA,
                   let lastB = lastB {
                    return (lastA, lastB)
                }
            }
            return nil
        }
        
        public typealias Element = (A.Element, B.Element)
        
    }
    
    let a: A
    let b: B
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(a: a, b: b)
    }
    
}

func concurrently<A, B>(
    _ a: A,
    _ b: B
)
-> AsyncThrowingStream<Either<A.Element, B.Element>, Error> where A: AsyncSequence, B: AsyncSequence {
    AsyncThrowingStream { continuation in
        let taskA = Task<Bool, Error> {
            for try await value in a {
                continuation.yield(.a(value))
            }
            return true
        }
        let taskB = Task<Bool, Error> {
            for try await value in b {
                continuation.yield(.b(value))
            }
            return true
        }
        Task {
            do {
                _ = try await taskA.value
                _ = try await taskB.value
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
    }
}

public struct Throttle<Base>: AsyncSequence where Base: AsyncSequence {
    
    init(
        base: Base,
        interval: UInt64
    ) {
        self.base = base
        self.interval = interval
    }
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = Base.Element
    
    public func makeAsyncIterator() -> Iterator {
        .init(
            base: base.makeAsyncIterator(),
            interval: interval
        )
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        init(
            base: Base.AsyncIterator,
            interval: UInt64
        ) {
            self.base = base
            self.interval = interval
        }
        
        var base: Base.AsyncIterator
        private var lastSent: UInt64?
        private let interval: UInt64
        
        public mutating func next() async throws -> Element? {
            if let lastSent = lastSent {
                var last = try await base.next()
                while time() - lastSent < interval {
                    last = try await base.next()
                }
                return last
            } else {
                let next = try await base.next()
                lastSent = time()
                return next
            }
        }
        
    }
    
    private let base: Base
    private let interval: UInt64
    
}

public struct DelayedSequence<Base>: AsyncSequence where Base: AsyncSequence {
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = Base.Element
    
    let base: Base
    let duration: UInt64
    
    public func makeAsyncIterator() -> Iterator {
        .init(base: base.makeAsyncIterator(),
              duration: duration * 1000)
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        var base: Base.AsyncIterator
        let duration: UInt64
        
        public mutating func next() async throws -> Element? {
            let next = try await base.next()
            await Task.sleep(duration)
            return next
        }
        
    }
    
}
