/// This protocol makes it easier to store a task for future cancellation when you
/// don't care about the type.
public protocol Subscription {
    func cancel()
}

extension Task: Subscription {
    
}

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
    
    @discardableResult
    func cancelled(by scope: SubscriptionScope) -> Task {
        scope.subscriptions.append(self)
        return self
    }
    
}
