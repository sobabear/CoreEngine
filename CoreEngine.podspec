#
# Be sure to run `pod lib lint CoreEngine.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CoreEngine'
  s.version          = '1.1.0'
  s.summary          = '🌪️ Simple and light-weighted unidirectional Data Flow in Swift'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
  
  # CoreKit

  Core is a framework for making more reactive applications inspired by [ReactorKit](https://github.com/ReactorKit/ReactorKit), [Redux](http://redux.js.org/docs/basics/index.html) with Combine. It's a very light weigthed and simple architecture, so you can either use CocoaPods or SPM to stay up to date, or just drag and drop into your project and go. Or you can look through it and roll your own.
  
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
       var action: Action? = nil
       
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
                       DESC

  s.homepage         = 'https://github.com/stareta1202/CoreEngine'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'stareta1202' => 'stareta1202@gmail.com' }
  s.source           = { :git => 'https://github.com/stareta1202/CoreEngine.git', :tag => s.version.to_s }
  s.social_media_url = 'https://www.sobabear.com'

  s.ios.deployment_target = '13.0'

  s.source_files = 'Sources/CoreEngine/Classes/**/*'
  
  # s.resource_bundles = {
  #   'CoreEngine' => ['CoreEngine/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
