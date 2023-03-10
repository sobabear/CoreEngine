import Foundation
import Combine

public protocol Core: ObservableObject {
    associatedtype Action
    associatedtype State
    associatedtype Error: Swift.Error
    associatedtype Effect: Publisher
    
    var subscription: Set<AnyCancellable> { get set }
    var action: ((Action) -> ()) { get }
    var state: State { get set }
    func mutate(state: State, action: Action) -> (State, Effect?)
    
}

extension Core {
    public var action: ((Action) -> ()) {
        let _newActionClosure: ((Action) -> ()) = { [weak self] _action in
            if let self = self {
                let (newState, effect) = self.mutate(state: self.state, action: _action)
                self.state = newState
                if let effect = effect {
                    effect
                        .sink(receiveCompletion: { completion in
                            if case let .failure(error) = completion {
                                // handle error
                            }
                        }, receiveValue: { value in
                            // handle value
                        })
                        .store(in: &self.subscription)
                }
            }
        }
        return _newActionClosure
    }
}
