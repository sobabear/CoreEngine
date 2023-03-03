import Foundation
import Combine

public protocol Core: ObservableObject {
    associatedtype Action
    associatedtype State
    
    var action: ((Action) -> ()) { get }
    var state: State { get set }
    func mutate(state: State, action: Action) -> State
}

extension Core {
    public var action: ((Action) -> ()) {
        let _newActionClosure: ((Action) -> ()) = { [weak self] _action in
            if let self = self {
                self.state = self.mutate(state: self.state, action: _action)
            }
        }
        return _newActionClosure
    }
}
