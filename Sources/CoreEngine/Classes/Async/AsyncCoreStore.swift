import Foundation

/// The single stored property AsyncCore conformers add to their actor.
/// Owns the lock-protected current state and the broadcaster.
public final class AsyncCoreStore<State: Equatable & Sendable>: Sendable {

    // @unchecked Sendable wrapper for mutable state protected by lock
    private final class LockedState: @unchecked Sendable {
        let lock = NSLock()
        var value: State

        init(_ initial: State) {
            value = initial
        }
    }

    private let lockedState: LockedState

    // Internal: accessed by AsyncCore extension to build AsyncCoreSequence.
    let broadcaster: AsyncCoreBroadcaster<State>

    public init(initialState: State) {
        lockedState = LockedState(initialState)
        broadcaster = AsyncCoreBroadcaster(initialState: initialState)
    }

    /// Lock-protected read — safe from any context including nonisolated.
    public var currentState: State {
        lockedState.lock.lock()
        defer { lockedState.lock.unlock() }
        return lockedState.value
    }

    /// Actor-internal: updates the lock and broadcasts to all subscribers.
    /// Not intended to be called directly by conformers.
    func update(_ newState: State) {
        lockedState.lock.lock()
        lockedState.value = newState
        lockedState.lock.unlock()
        broadcaster.send(newState)
    }
}
