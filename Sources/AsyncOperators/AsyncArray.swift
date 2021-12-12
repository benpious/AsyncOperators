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


/// Turns an Array into an `AsyncSequence`.
///
/// This is very useful for testing. 
public struct AsyncArray<Element>: AsyncSequence {
    
    let base: [Element]
    
    /// Initializer.
    public init(_ base: [Element]) {
        self.base = base
    }
    
    /// Initializer.
    public init(_ base: Element...) {
        self.base = base
    }

    public func makeAsyncIterator() -> Iterator {
        Iterator(base: base.makeIterator())
    }
    
    public struct Iterator: AsyncIteratorProtocol {
        
        public mutating func next() async -> Element? {
            base.next()
        }
        
        var base: Array<Element>.Iterator
        
    }
    
}

extension AsyncArray: Sendable where Element: Sendable {
    
}

