import Foundation
import Combine

public protocol Core: ObservableObject {
    associatedtype Action
    associatedtype State
    associatedtype Effect: Publisher
    
    var subscription: Set<AnyCancellable> { get set }
    var action: ((Action) -> ()) { get }
    var state: State { get set }
    func mutate(state: State, action: Action) -> (State, Effect?)
    func effect(output: Effect.Output)
    func handleError(error: Error)
}

extension Core {
    public var action: ((Action) -> ()) {
        let _newActionClosure: ((Action) -> ()) = { [weak self] _action in
            if let self = self {
                let (newState, effect) = self.mutate(state: self.state, action: _action)
                if let effect = effect {
                    effect
                        .sink(receiveCompletion: { [weak self] completion in
                            if case let .failure(error) = completion {
                                self?.handleError(error: error)
                            }
                        }, receiveValue: { [weak self] value in
                            self?.effect(output: value)
                        })
                        .store(in: &self.subscription)
                }
                self.state = newState
            }
        }
        return _newActionClosure
    }
    
    func handleError(error: Error) { }
    func effect(output: Effect.Output) { }
}
