# AsyncOperators

Under Construction. 

## What is this for? 

AsyncOperators brings some features of RxSwift/Combine to Structured Concurrency, 
such as `combineLatest` and `distinctUntilChanged`. 

Essentially, it allows you to construct complex sequences to vend to consumers of 
your code, like the following: 
```
let sequence = source
  .timeout(after: 1_000)
  .distinctElements()
  .combineWithLatest(from: source2)
  .startsWith((1, ""))
  .map { (a, b) in
     (a + 1, b)
  }
```
You then get results from the sequence using Structured Concurrency's equivalent of 
`subscribe`:
```
subscription = Task.detached {
    for try await (a, b) in sequence {
        print(a, b)
    }
}
```
