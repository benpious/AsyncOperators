public extension AsyncSequence {
    
    /// Prepends a value to the callee.
    func startsWith(_ start: Element) -> StartsWith<Self> {
        StartsWith(start: start, sequence: self)
    }
    
    /// Throws an error if a value is not appended before the timeout.
    func timeout(after milliseconds: UInt64) -> Timeout<Self> {
        Timeout(self, time: milliseconds)
    }
    
    /// Appends elements to the sequence only when the last value in `other` is `true`.
    func gated<Other>(
        by other: Other
    ) -> AsyncFilterSequence<AsyncCompactMapSequence<AsyncThrowingStream<Either<Self.Element, Bool>, Error>, (Self.Element, Bool)>>
    where Other: AsyncSequence, Other.Element == Bool {
        withLatestFrom(other: other).filter { element, shouldAppend in
            shouldAppend
        }
    }
    
    /// Terminates the sequence after the specified time interval.
    ///
    /// Unlike `timeout`, this does not throw an error.
    func terminate(
        afterMilliseconds milliseconds: UInt64
    ) -> AsyncThrowingStream<Self.Element, Error> {
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
    where Other: AsyncSequence {
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
    ) -> AsyncCompactMapSequence<AsyncThrowingStream<Either<Self.Element, Other.Element>, Error>, (Self.Element, Other.Element)>
    where Other: AsyncSequence {
        var lastOther: Other.Element?
        return concurrently(self, other)
            .compactMap { next -> (Element, Other.Element)? in
                switch next {
                case .a(let mine):
                    if let lastOther = lastOther {
                        return (mine, lastOther)
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
    ) -> AsyncCompactMapSequence<AsyncThrowingStream<Either<Poll.Element, Self.Element>, Error>, Self.Element> {
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
    
    typealias CombineLatestSequence<Element, Other> = AsyncCompactMapSequence<AsyncThrowingStream<Either<Element, Other.Element>, Error>, (Element, Other.Element)> where Other: AsyncSequence
        
}


