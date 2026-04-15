import Foundation

/// Lightweight, Sendable value type wrapping an AsyncCoreBroadcaster.
/// Each `for await` loop (or explicit makeAsyncIterator call) creates a fresh
/// subscription; the subscription is auto-cleaned when the iterator exits or
/// its task is cancelled.
@dynamicMemberLookup
public struct AsyncCoreSequence<State: Sendable>: AsyncSequence, Sendable {
    public typealias Element = State
    public typealias AsyncIterator = AsyncStream<State>.AsyncIterator

    private let broadcaster: AsyncCoreBroadcaster<State>

    init(broadcaster: AsyncCoreBroadcaster<State>) {
        self.broadcaster = broadcaster
    }

    public func makeAsyncIterator() -> AsyncStream<State>.AsyncIterator {
        broadcaster.subscribe().makeAsyncIterator()
    }

    // MARK: - @dynamicMemberLookup

    /// `for await count in core.states.count { ... }`
    public subscript<P: Sendable>(
        dynamicMember keyPath: KeyPath<State, P>
    ) -> AsyncMapSequence<AsyncStream<State>, P> {
        // KeyPath is @unchecked Sendable in the stdlib; warning is a known Swift limitation.
        broadcaster.subscribe().map { $0[keyPath: keyPath] }
    }

    // MARK: - Combinators

    public func map<Property: Sendable>(
        _ keyPath: KeyPath<State, Property>
    ) -> AsyncMapSequence<AsyncStream<State>, Property> {
        broadcaster.subscribe().map { $0[keyPath: keyPath] }
    }

    public func map<Transformed>(
        _ transform: @Sendable @escaping (State) async -> Transformed
    ) -> AsyncMapSequence<AsyncStream<State>, Transformed> {
        broadcaster.subscribe().map(transform)
    }

    public func map<Transformed>(
        _ transform: @Sendable @escaping (State) async throws -> Transformed
    ) -> AsyncThrowingMapSequence<AsyncStream<State>, Transformed> {
        broadcaster.subscribe().map(transform)
    }

    public func filter(
        _ isIncluded: @Sendable @escaping (State) async -> Bool
    ) -> AsyncFilterSequence<AsyncStream<State>> {
        broadcaster.subscribe().filter(isIncluded)
    }

    public func dropFirst(_ count: Int = 1) -> AsyncDropFirstSequence<AsyncStream<State>> {
        broadcaster.subscribe().dropFirst(count)
    }

    public func flatMap<SegmentOfResult: AsyncSequence>(
        _ transform: @Sendable @escaping (State) async throws -> SegmentOfResult
    ) -> AsyncThrowingFlatMapSequence<AsyncStream<State>, SegmentOfResult> {
        broadcaster.subscribe().flatMap(transform)
    }

    public func drop(
        while predicate: @Sendable @escaping (State) async -> Bool
    ) -> AsyncDropWhileSequence<AsyncStream<State>> {
        broadcaster.subscribe().drop(while: predicate)
    }
}
