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


/// This protocol makes it easier to store a task for future cancellation when you
/// don't care about the type.
public protocol Subscription {
    
    func cancel()
    
}

extension Task: Subscription {
    
}

/// Groups subscriptions, and cancells them all at once when it is
/// deinitialized or explicitly cancelled.
public final class SubscriptionScope: Subscription {
    
    var subscriptions: [Subscription] = []
    
    public func cancel() {
        for subscription in subscriptions {
            subscription.cancel()
        }
    }
    
    deinit {
        cancel()
    }
    
}

public extension Task {
    
    /// Cancels the callee when the scope is cancelled.
    @discardableResult
    func scoped(to scope: SubscriptionScope) -> Task {
        scope.subscriptions.append(self)
        return self
    }
    
}
