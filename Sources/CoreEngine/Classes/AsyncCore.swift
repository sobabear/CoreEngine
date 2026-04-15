import Foundation

public protocol AsyncCore: Actor {
    associatedtype Action: Sendable
    associatedtype State: Equatable & Sendable

    nonisolated var store: AsyncCoreStore<State> { get }
    func reduce(state: State, action: Action) async throws -> State
    func handleError(error: Error) async
}

public extension AsyncCore {

    /// Lock-protected read — safe from any context including nonisolated.
    nonisolated var currentState: State { store.currentState }

    /// Multicast async sequence. Each iteration creates a fresh subscription.
    nonisolated var states: AsyncCoreSequence<State> {
        AsyncCoreSequence(broadcaster: store.broadcaster)
    }

    /// Fire-and-forget dispatch. Creates an unstructured task that hops to the
    /// actor's executor and calls reduce, then broadcasts if state changed.
    nonisolated func send(_ action: Action) {
        Task { await _process(action) }
    }

    /// Dynamic member read on state: `core.count`
    subscript<T>(dynamicMember keyPath: KeyPath<State, T>) -> T {
        currentState[keyPath: keyPath]
    }

    /// Select a derived value and observe only those changes.
    func select<Selected: Sendable>(
        _ selector: @escaping @Sendable (State) -> Selected
    ) -> AsyncMapSequence<AsyncStream<State>, Selected> {
        states.map(selector)
    }

    /// Default no-op error handler — override to handle errors.
    func handleError(error: Error) async { }
}

private extension AsyncCore {
    /// Runs inside actor isolation. Reduces, deduplicates, then broadcasts.
    func _process(_ action: Action) async {
        do {
            let current = store.currentState
            let newState = try await reduce(state: current, action: action)
            guard newState != current else { return }
            store.update(newState)
        } catch {
            await handleError(error: error)
        }
    }
}
