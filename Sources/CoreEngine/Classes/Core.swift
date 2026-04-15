import Foundation

@dynamicMemberLookup
@dynamicCallable
public protocol Core: AnyObject {
    associatedtype Action
    associatedtype State: Equatable & Sendable

    var state: State { get set }
    func reduce(state: State, action: Action) -> State
}

extension Core {
    /// Reduce and set state. No-op if the new state equals the current state.
    public func action(_ action: Action) {
        let newState = reduce(state: state, action: action)
        guard newState != state else { return }
        state = newState
    }

    /// Supports `core(.increase, .decrease)` call syntax.
    public func dynamicallyCall(withArguments actions: [Action]) {
        actions.forEach { action($0) }
    }

    /// Supports `core.count` read syntax.
    public subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        state[keyPath: keyPath]
    }
}
