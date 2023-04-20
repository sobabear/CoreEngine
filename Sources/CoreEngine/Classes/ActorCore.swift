import Foundation

public protocol ActorCore: Actor {
    associatedtype Action
    associatedtype State

    var action: ((Action) -> ()) { get }
    var state: State { get set }
    func reduce(state: State, action: Action) async throws
    func handleError(error: Error) async
}

extension ActorCore {
    var _state: State {
        return self.state
    }
    public var action: ((Action) -> ()) {
        let _newActionClosure: ((Action) -> ()) = { [weak self] _action in
            if let self = self {
                Task {
                    do {
                        _ = try await self.reduce(state: self._state, action: _action)
                    } catch {
                        await self.handleError(error: error)
                    }
                }   
            }
        }
        return _newActionClosure
    }
    
    public func handleError(error: Error) { }
}
