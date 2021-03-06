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


public extension AsyncSequence {
    
    /// Prepends a value to the callee.
    func startsWith(_ start: Element) -> StartsWith<Self> where Self: Sendable {
        StartsWith(start: start, sequence: self)
    }
    
    /// Throws an error if a value is not appended before the timeout.
    func timeout(after milliseconds: UInt64) -> Timeout<Self> where Self: Sendable {
        Timeout(self, time: milliseconds)
    }
    
    /// Appends elements to the sequence only when the last value in `other` is `true`.
    func gated<Other>(
        by other: Other
    ) -> GatedBySequence<Element>
    where Other: AsyncSequence & Sendable,
            Self: Sendable,
            Other.Element == Bool {
               withLatestFrom(other: other)
                    .filter { (pair: Pair<Self.Element, Bool>) -> Bool in
                        pair.b
                    }
    }
    
    /// Terminates the sequence after the specified time interval.
    ///
    /// Unlike `timeout`, this does not throw an error.
    func terminate(
        afterMilliseconds milliseconds: UInt64
    ) -> AsyncThrowingStream<Self.Element, Error>
    where Self: Sendable {
        AsyncThrowingStream<Element, Error> { continuation in
            let task = Task {
                for try await value in self {
                    guard !Task.isCancelled else {
                        return
                    }
                    continuation.yield(value)
                }
                continuation.finish()
            }
            Task {
                await Task.sleep(milliseconds * 1000)
                task.cancel()
                continuation.finish()
            }
        }
    }
    
    /// Combines the latest value of the callee with the latest value of
    /// `other` each time either one appends a value.
    func combineWithLatest<Other>(
        from other: Other
    ) -> CombineLatestSequence<Element, Other>
    where Other: AsyncSequence & Sendable, Self: Sendable {
        var lastA: Element?
        var lastB: Other.Element?
        return concurrently(self, other)
            .compactMap { next -> (Element, Other.Element)? in
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
                return nil
            }
    }
    
    /// Whenever the callee appends a value, combines with the last value
    /// appended by `other`.
    func withLatestFrom<Other>(
        other: Other
    ) -> WithLatestFromSequence<Element, Other>
    where Other: AsyncSequence & Sendable, Self: Sendable {
        var lastOther: Other.Element?
        return concurrently(self, other)
            .compactMap { next -> Pair<Element, Other.Element>? in
                switch next {
                case .a(let mine):
                    if let lastOther = lastOther {
                        return .init(mine, lastOther)
                    } else {
                        return nil
                    }
                case .b(let other):
                    lastOther = other
                    return nil
                }
            }
    }
    
    /// Appends the last value appended in the time interval
    /// specified by `milliseconds`.
    func debounce(
        milliseconds: UInt64
    ) -> DebounceSequence<Element> where Self: Sendable {
        var lastMine: Element?
        return concurrently(Poll(nanoseconds: milliseconds * 1000), self)
            .compactMap { next -> Element? in
                switch next {
                case .a:
                    if let last = lastMine {
                        lastMine = nil
                        return last
                    } else {
                        return nil
                    }
                case .b(let mine):
                    lastMine = mine
                    return nil
                }
            }
    }
    
    /// Filters subsequent duplicate elements in the callee.
    func distinctElements() -> DistinctUntilChanged<Self> where Element: Equatable {
        .init(base: self)
    }
    
    /// Adds an additional delay before each element is appended, including the
    /// first.
    func delayElements(byMilliseconds milliseconds: UInt64) -> DelayedSequence<Self> {
        .init(base: self, duration: milliseconds)
    }
            
}

public typealias CombineLatestSequence<Element, Other> = AsyncCompactMapSequence<AsyncThrowingStream<Either<Element, Other.Element>, Error>, (Element, Other.Element)> where Other: AsyncSequence

public typealias DebounceSequence<Element> = AsyncCompactMapSequence<AsyncThrowingStream<Either<Poll.Element, Element>, Error>, Element>

public typealias WithLatestFromSequence<Element, Other> = AsyncCompactMapSequence<AsyncThrowingStream<Either<Element, Other.Element>, Error>, Pair<Element, Other.Element>> where Other: AsyncSequence

public typealias GatedBySequence<Element> = AsyncFilterSequence<AsyncCompactMapSequence<AsyncThrowingStream<Either<Element, Bool>, Error>, Pair<Element, Bool>>>

extension DebounceSequence: @unchecked Sendable where Element: Sendable {
    
}

public struct Pair<A, B> {
    
    init(_ a: A, _ b: B) {
        self.a = a
        self.b = b
    }
    
    var a: A
    var b: B
}

extension Pair: Sendable where A: Sendable, B: Sendable {
    
}
