import XCTest
@testable import AsyncOperators

final class AsyncOperatorsTests: XCTestCase {
    
    func test_throttle() async throws {
        let poll = AsyncArray(0, 1, 2, 3)
            .delayElements(byMilliseconds: 20)
            .throttle(milliseconds: 50)
            .prefix(5)
        for try await result in poll {
            print(result)
        }
    }
    
    func test_just() async {
        let just = Just("test")
        var emittedOnce = false
        for await result in just {
            if emittedOnce {
                XCTFail("Emitted more than once: \(result)")
            } else {
                emittedOnce = true
            }
        }
    }
    
    func test_combine_latest() async throws {
        let source = AsyncSource<Int>(1)
        let source2 = Just("test")
        let r = source
            .combineWithLatest(from: source2)
            .map { (a, b) in
                (a + 1, b)
            }
        for try await (a, b) in r {
            XCTAssert(a == 2)
            XCTAssert(b == "test")
            return
        }
    }
    
    
    func test_errors_are_propogated() async throws {
        let source = JustError(TestError())
            .startsWith(8)
            .combineWithLatest(from: AsyncArray(0, 1, 2, 3))
        var gotError = false
        do {
            for try await _ in source {
                
            }
        } catch {
            gotError = true
        }
        XCTAssertTrue(gotError)
    }
}


struct TestError: Error {
    
}
