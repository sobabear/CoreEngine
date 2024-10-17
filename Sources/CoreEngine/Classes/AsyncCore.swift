import Foundation

public protocol AsyncCore: Actor {
    associatedtype Action
    associatedtype State
    
    var action: ((Action) async -> ()) { get }
    nonisolated var currentState: State { get set }
    var states: AsyncCoreSequence<State> { get }
    var continuation: AsyncStream<State>.Continuation { get }
    
    func reduce(state: State, action: Action) async throws -> State
    func handleError(error: Error) async
}

public extension AsyncCore {
    var action: ((Action) async -> ()) {
        let newActionClosure: ((Action) async -> ()) = { [weak self] _action in
            guard let self = self else { return }
            do {
                let reducedState = try await self.reduce(state: self.currentState, action: _action)
                await self.update(state: reducedState)
            } catch {
                await self.handleError(error: error)
            }
        }
        return newActionClosure
    }
    
    func dynamicallyCall(withArguments actions: [Action]) async {
        for action in actions {
            await self.action(action)
        }
    }
    
    subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        return currentState[keyPath: keyPath]
    }
    
    nonisolated func send(_ action: Action) {
        Task {
            await self.action(action)
        }
    }
    
    func handleError(error: Error) async { }
}

private extension AsyncCore {
    private func update(state: State) async {
        self.currentState = state
        continuation.yield(self.currentState)
        self.states.send(state)
    }
}
