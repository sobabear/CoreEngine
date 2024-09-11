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

[Swift Package Manager](https://swift.org/package-manager/) is a tool for managing the distribution of Swift code. It’s integrated with the Swift build system to automate the process of downloading, compiling, and linking dependencies.


To integrate SnapKit into your Xcode project using Swift Package Manager, add it to the dependencies value of your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/sobabear/CoreEngine.git", .upToNextMajor(from: "1.3.0"))
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
- Concurrency-First: Built for Swift's native concurrency model, using async/await to handle asynchronous actions.
- Simplified State Management: AsyncCore simplifies reactive architecture by providing built-in async state streams and an efficient way to dispatch actions.
- Error Handling and Side Effects: AsyncCore includes streamlined error handling and support for asynchronous side effects.
- Thread Safety: Since AsyncCore is built on top of Swift’s Actor system, it ensures thread-safe access to state and actions.
  
  ## Example
  
  See details on Example
  
  ```swift
  /// on ViewController with Core
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
     self.core.action(.increase, .decrease)
   }

   
   func bind() {
     core.$state.map(\.count)
         .sink { [weak self] count in
             self?.label.text = "\(count)"
         }
         .store(in: &subscription)
   }
   ...

   /// on ViewController with AsyncCore
    class ViewController: UIViewController {
        private var core: AsyncMainCore?

        override func viewDidLoad() {
            super.viewDidLoad()
            
            Task {
                let core = await AsyncMainCore(initialState: .init())
                self.core = core
                self.bind(core: core)
            }
        }

        private func bind(core: AsyncMainCore) {
            Task {
                for await count in core.states.map(\.count) {
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
    actor AsyncMainCore: AsyncCore {
        var currentState: State

        enum Action: Equatable, Hashable {
            case increase
            case decrease
        }

        struct State: Equatable, Sendable {
            var count = 0
        }

        var states: AsyncCoreSequence<State>
        var continuation: AsyncStream<State>.Continuation

        init(initialState: State) async {
            self.currentState = initialState
            let (states, continuation) = AsyncStream<State>.makeStream()
            self.states = await .init(states)
            self.continuation = continuation
        }

        func reduce(state: State, action: Action) async -> State {
            var newState = state
            switch action {
            case .increase:
                newState.count += 1
            case .decrease:
                newState.count -= 1
            }
            return newState
        }
    }
   
   class MainCore: Core {
       var subscription: Set<AnyCancellable> = .init()
       
       enum Action: Equatable, Hashable {
           case increase
           case decrease
       }
       
       struct State: Equatable {
           var count = 0
       }

       @Published var state: State = .init()

       func reduce(state: State, action: Action) -> State {
           var newState = state
           switch action {
           case .decrease:
               newState.count -= 1
           case .increase:
               newState.count += 1
           }
           return newState
       }
   }
   
   ```
   
   
## Side Effect & Error Handling
   
Not just simple core, but complex core is also supported. For example, Side Effect and Error handling. When it comes to those, you use ```AsyncCore or PublisherCore```.

It is not very different from Core, since AnyCore also conforms.

### func dispatch(effect: any Publisher) & func handleError(error: Error)
This method is defined in AnyCore and when you deal with side-effect generated publisher send into the function. Also you can handle every errors on the ```handleError(error: Error)``` function

Here is an example of the ``` PublisherCore```
 

   ```swift
class MainCore: PublisherCore {
    var subscription: Set<AnyCancellable> = .init()

    enum Action {
        case increase
        case decrease
        case jump(Int)
        case setNumber(Int)
    }

    struct State {
        var count = 0
    }

    @Published var state: State = .init()
    @Published var tenGap: Int = 10
    
    private let sessionService = SessionService()
    
    init {
        dispatch(effect: sessionService.randomUInt$().map(Action.setNumber))
    }
    
    func reduce(state: State, action: Action) -> State {
        var newState = state
        
        switch action {
        case .increase:
            newState.count += 1
        case .decrease:
            newState.count -= 1
        case let .jump(value):
            newState.count += value
        case let .setNumber(value):
            newState.count = value
        }
        return newState
    }
    
    func handleError(error: Error) {
        if let errpr = error as? MyError {
            //handle
        }
    }
    
    func tenJumpAction() {
        self.dispatch(effect: $tenGap.map(Action.jump))
    } 
}


class SessionService {
    func randomUInt$() -> AnyPublisher<Int, Error> {
    // blahblah
    }
}

   
   ```
## Examples + RxSwift

copy those code for RxSwift
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
                if let self {
                    self.state = self.reduce(state: self.state, action: $0)
                }
                
            }, onError: { [weak self] in
                self?.handleError(error: $0)
            })
            .disposed(by: disposeBag)
    }
    
    public func handleError(error: Error) { }
}


@propertyWrapper
class ObservableProperty<Element>: ObservableType {
  var wrappedValue: Element {
    didSet {
      subject.onNext(wrappedValue)
    }
  }
  
  private let subject: BehaviorSubject<Element>
  
  init(wrappedValue: Element) {
    self.wrappedValue = wrappedValue
    self.subject = BehaviorSubject<Element>(value: wrappedValue)
  }
  
  var projectedValue: Observable<Element> {
    return subject.asObservable()
  }
  
  func subscribe<Observer>(_ observer: Observer) -> Disposable where Observer : ObserverType, Element == Observer.Element {
    return subject.subscribe(observer)
  }
}

```

## Author

stareta1202, stareta1202@gmail.com

## License

CoreEngine is available under the MIT license. See the LICENSE file for more info.

   
   
