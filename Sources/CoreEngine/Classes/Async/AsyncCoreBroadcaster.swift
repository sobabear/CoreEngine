import Foundation
import os

// Thread-safe multicast broadcaster. Replays last value to new subscribers.
// Auto-removes cancelled subscribers via onTermination callback.
// Internal type — not part of the public API.
//
// @unchecked Sendable: all mutable state is guarded by `lock` (OSAllocatedUnfairLock).
// Swift cannot verify lock-based thread safety mechanically, so the conformance is
// declared @unchecked with the invariant documented here.
final class AsyncCoreBroadcaster<State: Sendable>: @unchecked Sendable {

    private struct Storage {
        var continuations: [UUID: AsyncStream<State>.Continuation] = [:]
        var last: State
    }

    private let lock: OSAllocatedUnfairLock<Storage>

    init(initialState: State) {
        lock = OSAllocatedUnfairLock(initialState: Storage(last: initialState))
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
                self.lock.withLock { $0.continuations[id] = nil }
            }
            // Atomically register continuation and get last value so no send() is missed.
            let last = lock.withLock { storage -> State in
                storage.continuations[id] = continuation
                return storage.last
            }
            continuation.yield(last)
        }
    }

    /// Broadcasts a new state to all live subscribers and updates the replay value.
    /// Continuations are snapshot under the lock and yielded outside it to prevent
    /// re-entrant lock acquisition if onTermination fires during yield.
    func send(_ state: State) {
        let snapshot = lock.withLock { storage -> [AsyncStream<State>.Continuation] in
            storage.last = state
            return Array(storage.continuations.values)
        }
        for continuation in snapshot {
            continuation.yield(state)
        }
    }
}
