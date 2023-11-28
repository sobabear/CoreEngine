import Foundation
import Combine

@dynamicMemberLookup
@dynamicCallable
public protocol Core: ObservableObject {
    associatedtype Action
    associatedtype State

    var action: ((Action) -> ()) { get }
    var state: State { get set }
    func reduce(state: State, action: Action) -> State   
}

extension Core {
    public var action: ((Action) -> ()) {
        let _newActionClosure: ((Action) -> ()) = { [weak self] _action in
            if let self = self {
                self.state = self.reduce(state: self.state, action: _action)
            }
        }
        return _newActionClosure
    }
    
    public func dynamicallyCall(withArguments actions: [Action]) {
        actions.forEach({ self.action($0) })
    }
    
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        return state[keyPath: keyPath]
    }
}
