import os

/// The single stored property AsyncCore conformers add to their actor.
/// Owns the lock-protected current state and the broadcaster.
public final class AsyncCoreStore<State: Equatable & Sendable>: Sendable {

    private let stateLock: OSAllocatedUnfairLock<State>

    // Internal: accessed by AsyncCore extension to build AsyncCoreSequence.
    let broadcaster: AsyncCoreBroadcaster<State>

    public init(initialState: State) {
        stateLock = OSAllocatedUnfairLock(initialState: initialState)
        broadcaster = AsyncCoreBroadcaster(initialState: initialState)
    }

    /// Lock-protected read — safe from any context including nonisolated.
    public var currentState: State {
        stateLock.withLock { $0 }
    }

    /// Actor-internal: updates the lock and broadcasts to all subscribers.
    /// Not intended to be called directly by conformers.
    func update(_ newState: State) {
        stateLock.withLock { $0 = newState }
        broadcaster.send(newState)
    }
}
