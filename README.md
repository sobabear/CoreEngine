# CoreEngine

[![CI Status](https://img.shields.io/travis/stareta1202/CoreEngine.svg?style=flat)](https://travis-ci.org/stareta1202/CoreEngine)
[![Version](https://img.shields.io/cocoapods/v/CoreEngine.svg?style=flat)](https://cocoapods.org/pods/CoreEngine)
[![License](https://img.shields.io/cocoapods/l/CoreEngine.svg?style=flat)](https://cocoapods.org/pods/CoreEngine)
[![Platform](https://img.shields.io/cocoapods/p/CoreEngine.svg?style=flat)](https://cocoapods.org/pods/CoreEngine)

  Core is a framework for making more reactive applications inspired by [ReactorKit](https://github.com/ReactorKit/ReactorKit), [Redux](http://redux.js.org/docs/basics/index.html) with Combine. It's a very light weigthed and simple architecture, so you can either use CocoaPods or SPM to stay up to date, or just drag and drop into your project and go. Or you can look through it and roll your own.

## Installation
CoreEngine is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'CoreEngine'
```



  
  ## Example
  
  See details on Example
  
  ```swift
  // on ViewController
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
   
   func bind() {
     core.$state.map(\.count)
         .sink { [weak self] count in
             self?.label.text = "\(count)"
         }
         .store(in: &subscription)
   }
   ...
   ```
   
   ```swift
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

       func mutate(state: State, action: Action) -> State {
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

## Author

stareta1202, stareta1202@gmail.com

## License

CoreEngine is available under the MIT license. See the LICENSE file for more info.
