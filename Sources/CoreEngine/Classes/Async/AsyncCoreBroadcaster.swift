import Foundation

// Thread-safe multicast broadcaster. Replays last value to new subscribers.
// Auto-removes cancelled subscribers via onTermination callback.
// Internal type — not part of the public API.
//
// @unchecked Sendable: all mutable state is guarded by `lock` (NSLock).
// Swift cannot verify lock-based thread safety mechanically, so the conformance is
// declared @unchecked with the invariant documented here.
final class AsyncCoreBroadcaster<State: Sendable>: @unchecked Sendable {

    private struct Storage {
        var continuations: [UUID: AsyncStream<State>.Continuation] = [:]
        var last: State
    }

    // @unchecked Sendable wrapper for mutable storage protected by lock
    private final class LockedStorage: @unchecked Sendable {
        let lock = NSLock()
        var storage: Storage

        init(_ initial: Storage) {
            storage = initial
        }
    }

    private let lockedStorage: LockedStorage

    init(initialState: State) {
        lockedStorage = LockedStorage(Storage(last: initialState))
    }

    /// Creates a new subscription. Replays the last value immediately.
    /// Automatically removes the subscription when the iterator exits or is cancelled.
    func subscribe() -> AsyncStream<State> {
        let id = UUID()
        return AsyncStream<State> { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }
            continuation.onTermination = { [weak self] _ in
                guard let self else { return }
                self.lockedStorage.lock.lock()
                self.lockedStorage.storage.continuations[id] = nil
                self.lockedStorage.lock.unlock()
            }
            // Atomically register continuation and get last value so no send() is missed.
            lockedStorage.lock.lock()
            lockedStorage.storage.continuations[id] = continuation
            let last = lockedStorage.storage.last
            lockedStorage.lock.unlock()
            continuation.yield(last)
        }
    }

    /// Broadcasts a new state to all live subscribers and updates the replay value.
    /// Continuations are snapshot under the lock and yielded outside it to prevent
    /// re-entrant lock acquisition if onTermination fires during yield.
    func send(_ state: State) {
        lockedStorage.lock.lock()
        lockedStorage.storage.last = state
        let snapshot = Array(lockedStorage.storage.continuations.values)
        lockedStorage.lock.unlock()
        for continuation in snapshot {
            continuation.yield(state)
        }
    }
}
