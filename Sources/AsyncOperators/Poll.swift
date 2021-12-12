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

/// A async sequence that appends a new value after some time passes.
///
/// This sequence is "cold" in the sense that it does not start working
/// until you start enumerating it. 
///
/// - Note: this sequence never terminates.
public struct Poll: AsyncSequence, Sendable {
    
    public typealias AsyncIterator = Iterator
    
    public typealias Element = ()
    
    public struct Iterator: AsyncIteratorProtocol {
        
        let duration: UInt64
        
        public func next() async -> ()? {
            guard !Task.isCancelled else {
                return nil
            }
            return await Task.sleep(duration)
        }
        
    }
    
    public func makeAsyncIterator() -> Iterator {
        Iterator(duration: duration)
    }
    
    let duration: UInt64
    
    public init(nanoseconds: UInt64) {
        self.duration = nanoseconds
    }
    
}
