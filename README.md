# CoreEngine
[![CI](https://github.com/sobabear/CoreEngine/actions/workflows/ci.yml/badge.svg)](https://github.com/sobabear/CoreEngine/actions/workflows/ci.yml)
[![Version](https://img.shields.io/github/v/tag/sobabear/CoreEngine?label=version&sort=semver)](https://github.com/sobabear/CoreEngine/releases)
[![License](https://img.shields.io/cocoapods/l/CoreEngine.svg?style=flat)](https://cocoapods.org/pods/CoreEngine)

### Simple and light
![image](https://user-images.githubusercontent.com/47838132/224374882-38cd9b39-9317-4efb-8b16-d320c434d23e.png)
 Core is a framework for making more reactive applications inspired by [ReactorKit](https://github.com/ReactorKit/ReactorKit), [Redux](http://redux.js.org/docs/basics/index.html).  
### Scalability
 Core is  Reactive independent Framework which means you can expand whatever you want to import such as [Combine](https://developer.apple.com/documentation/combine), [RxSwift](https://github.com/ReactiveX/RxSwift).

It's a very light weigthed and simple architecture, so you can either use CocoaPods or SPM to stay up to date, or just drag and drop into your project and go. Or you can look through it and roll your own.

## Installation
CoreEngine is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

### CocoaPods

```ruby
pod 'CoreEngine'
```

### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It's integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.


To integrate CoreEngine into your Xcode project using Swift Package Manager, add it to the dependencies value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sobabear/CoreEngine.git", .upToNextMajor(from: "2.0.0"))
]
```

## Performance
<img width="914" alt="Screenshot 2023-04-28 at 1 39 26 PM" src="https://user-images.githubusercontent.com/47838132/235057288-8f17a13d-2ed8-475e-9607-442151ecbff6.png">


Core Engine is insanely fast and light-weight compared to similar frameworks
you can check details here [CoreEngineBenchMark](https://github.com/sobabear/CoreEngineBenchMark)


## Highly Recommended: Using AsyncCore

While CoreEngine provides both traditional reactive approaches and state management patterns, we highly recommend using AsyncCore for modern, asynchronous, and more efficient state handling.

AsyncCore leverages Swift's structured concurrency with async/await, providing a clean and intuitive way to manage state updates, handle side effects, and ensure thread safety with Swift's Actor model.

### Why Use AsyncCore?
- **Concurrency-First:** Built for Swift's native concurrency model, using async/await to handle asynchronous actions.
- **Simplified State Management:** One stored property (`store`) replaces the previous three-property boilerplate.
- **Data-Race Free:** State is lock-protected via `OSAllocatedUnfairLock`; no `nonisolated(unsafe)` required.
- **Memory Safe:** Cancelled subscribers are automatically removed from the broadcaster.
- **Deduplication:** State emissions are skipped when `reduce` returns an equal state.
- **Thread Safety:** Built on Swift's Actor system with Swift 6 strict concurrency.
  
  ## Example

  ```swift
  /// ViewController with Core
  let label = UILabel()
  let increaseButton = UIButton()
  let decreaseButton = UIButton()
  var core: MainCore = .init()
  
  func increaseButtonTapped() {
    self.core.action(.increase)
  }
  
  func decreaseButtonTapped() {
    self.core.action(.decrease)
  }

  func multipleActions() {
    self.core(.increase, .decrease)  // @dynamicCallable syntax
  }

  func bind() {
    core.$state.map(\.count)
        .sink { [weak self] count in
            self?.label.text = "\(count)"
        }
        .store(in: &subscription)
  }

  /// ViewController with AsyncCore (v2)
  class ViewController: UIViewController {
      private var core: AsyncMainCore?

      override func viewDidLoad() {
          super.viewDidLoad()

          // init is synchronous in v2 — no await needed
          let core = AsyncMainCore(initialState: .init())
          self.core = core
          self.bind(core: core)
      }

      private func bind(core: AsyncMainCore) {
          Task {
              for await count in core.states.map(\.count) {
                  print("Count: \(count)")
              }
          }
          Task {
              // @dynamicMemberLookup: iterate a single property directly
              for await count in core.states.count {
                  print("Count: \(count)")
              }
          }
      }

      @IBAction func increaseTapped() {
          core?.send(.increase)
      }

      @IBAction func decreaseTapped() {
          core?.send(.decrease)
      }
  }
  ```

  ```swift
  // AsyncCore conformance (v2) — one stored property, synchronous init
  actor AsyncMainCore: AsyncCore {
      let store: AsyncCoreStore<State>

      enum Action: Sendable {
          case increase
          case decrease
      }

      struct State: Equatable, Sendable {
          var count = 0
      }

      init(initialState: State) {
          self.store = .init(initialState: initialState)
      }

      func reduce(state: State, action: Action) async throws -> State {
          var newState = state
          switch action {
          case .increase: newState.count += 1
          case .decrease: newState.count -= 1
          }
          return newState
      }
  }

  // Core conformance — unchanged call syntax
  class MainCore: Core {
      enum Action: Equatable, Hashable {
          case increase
          case decrease
      }

      struct State: Equatable, Sendable {
          var count = 0
      }

      @Published var state: State = .init()

      func reduce(state: State, action: Action) -> State {
          var newState = state
          switch action {
          case .decrease: newState.count -= 1
          case .increase: newState.count += 1
          }
          return newState
      }
  }
  ```


## Side Effect & Error Handling
   
Not just simple core, but complex core is also supported. For example, Side Effect and Error handling. When it comes to those, you use `AsyncCore or PublisherCore`.

### func dispatch(effect: any Publisher) & func handleError(error: Error)
This method is defined in `PublisherCore` and when you deal with side-effect generated publisher send into the function. Also you can handle every errors on the `handleError(error: Error)` function.

   ```swift
class MainCore: PublisherCore {
    var subscription: Set<AnyCancellable> = .init()

    enum Action {
        case increase
        case decrease
        case setNumber(Int)
    }

    struct State: Equatable, Sendable {
        var count = 0
    }

    @Published var state: State = .init()
    
    private let sessionService = SessionService()
    
    init() {
        dispatch(effect: sessionService.randomUInt$().map(Action.setNumber))
    }
    
    func reduce(state: State, action: Action) -> State {
        var newState = state
        switch action {
        case .increase: newState.count += 1
        case .decrease: newState.count -= 1
        case let .setNumber(value): newState.count = value
        }
        return newState
    }
    
    func handleError(error: Error) {
        // handle
    }
}
   ```

---

## Migration Guide (v1 → v2)

| Breaking change | Migration |
|---|---|
| `State` must conform to `Equatable & Sendable` | Add conformances to all `State` structs |
| `AsyncCore` removes `currentState`, `states`, `continuation` protocol requirements | Replace 3 properties + async init with `let store: AsyncCoreStore<State>` + sync init |
| `AsyncCore.init` is no longer `async` | Remove `await` from init call sites |
| `Core.action` is a method, not a closure property | `core.action(.x)` unchanged; `let fn = core.action` no longer compiles |
| iOS 13/14/15 no longer supported | Update deployment targets to iOS 16+ |

### Before (v1)

```swift
actor MyCore: AsyncCore {
    nonisolated(unsafe) var currentState: State
    var states: AsyncCoreSequence<State>
    var continuation: AsyncStream<State>.Continuation

    init(initialState: State) async {
        self.currentState = initialState
        let (stream, continuation) = AsyncStream<State>.makeStream()
        self.states = await .init(stream)
        self.continuation = continuation
    }
}

// Call site
let core = await MyCore(initialState: .init())
```

### After (v2)

```swift
actor MyCore: AsyncCore {
    let store: AsyncCoreStore<State>

    init(initialState: State) {
        self.store = .init(initialState: initialState)
    }
}

// Call site — no await
let core = MyCore(initialState: .init())
```

---

## Examples + RxSwift

```swift
import Foundation
import CoreEngine
import RxSwift

protocol RxCore: Core {
    var disposeBag: DisposeBag { get set }
    
    func mutate(effect: Observable<Action>)
    func handleError(error: Error)
}

extension RxCore {
    public func mutate(effect: Observable<Action>) {
        effect
            .subscribe(onNext: { [weak self] in
                self?.action($0)
            }, onError: { [weak self] in
                self?.handleError(error: $0)
            })
            .disposed(by: disposeBag)
    }
    
    public func handleError(error: Error) { }
}
```

## Author

stareta1202, stareta1202@gmail.com

## License

CoreEngine is available under the MIT license. See the LICENSE file for more info.
