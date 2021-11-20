public extension AsyncSequence {
    
    /// Prepends a value to the callee.
    func startsWith(_ start: Element) -> StartsWith<Self> {
        StartsWith(start: start, sequence: self)
    }
    
    /// Throws an error if a value is not emitted before the timeout.
    func timeout(after milliseconds: UInt64) -> Timeout<Self> {
        Timeout(self, time: milliseconds)
    }
    
    /// Combines the latest value of the callee with the latest value of
    /// `other` each time either one emits.
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
    
    func throttle(milliseconds: UInt64) -> Throttle<Self> {
        Throttle(base: self, interval: Double(milliseconds))
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


