import Foundation
@testable import CoreEngine
import XCTest

// MARK: - Test conformers

private actor DeduplicationCore: AsyncCore {
    let store: AsyncCoreStore<State>
    init(initialState: State) { store = .init(initialState: initialState) }

    enum Action: Sendable { case increment, noChange }
    struct State: Equatable, Sendable { var count: Int }

    func reduce(state: State, action: Action) async throws -> State {
        var s = state
        switch action {
        case .increment: s.count += 1
        case .noChange: break          // returns same state — triggers deduplication
        }
        return s
    }
}

// MARK: - AsyncCore tests

final class CoreEngineV2AsyncCoreTests: XCTestCase {

    /// Same state returned by reduce → no emission.
    func testDeduplication() async {
        let core = DeduplicationCore(initialState: .init(count: 0))

        var iter = core.states.makeAsyncIterator()
        let initial = await iter.next()
        XCTAssertEqual(initial?.count, 0)

        core.send(.increment)
        let after1 = await iter.next()
        XCTAssertEqual(after1?.count, 1)

        // .noChange returns the same state → deduplication must skip emission
        core.send(.noChange)

        // .increment should be the next (and only next) emission
        core.send(.increment)
        let after2 = await iter.next()
        XCTAssertEqual(after2?.count, 2)  // if noChange emitted, this would block
    }

    /// Multiple concurrent subscribers all receive the broadcast value.
    func testConcurrentSubscribers() async {
        let core = DeduplicationCore(initialState: .init(count: 0))

        // Create three independent iterators (each registers a subscription)
        var iter1 = core.states.makeAsyncIterator()
        var iter2 = core.states.makeAsyncIterator()
        var iter3 = core.states.makeAsyncIterator()

        // Drain initial replay from each
        _ = await iter1.next()
        _ = await iter2.next()
        _ = await iter3.next()

        core.send(.increment)

        let v1 = await iter1.next()
        let v2 = await iter2.next()
        let v3 = await iter3.next()

        XCTAssertEqual(v1?.count, 1)
        XCTAssertEqual(v2?.count, 1)
        XCTAssertEqual(v3?.count, 1)
    }

    /// Cancelled subscriber is removed; system still works and remaining subscribers
    /// receive subsequent broadcasts.
    func testContinuationCleanup() async throws {
        let core = DeduplicationCore(initialState: .init(count: 0))

        // Subscribe with a task that immediately exits after first value
        let shortLivedTask = Task {
            for await _ in core.states { break }
        }
        await shortLivedTask.value
        // Give onTermination a moment to fire and remove the continuation
        try await Task.sleep(nanoseconds: 10_000_000)

        // A new subscriber should still work correctly after cleanup
        var iter = core.states.makeAsyncIterator()
        _ = await iter.next()  // initial replay

        core.send(.increment)
        let val = await iter.next()
        XCTAssertEqual(val?.count, 1)
    }

    /// currentState is safe to read from a non-actor context via lock.
    func testNonisolatedCurrentStateRead() async {
        let core = DeduplicationCore(initialState: .init(count: 0))

        var iter = core.states.makeAsyncIterator()
        _ = await iter.next()  // initial

        core.send(.increment)
        _ = await iter.next()  // wait for actor to process

        // This call is from a nonisolated context — must return 1
        let count = core.currentState.count
        XCTAssertEqual(count, 1)
    }

    /// AsyncCore conformance initialises synchronously — no `await` needed.
    func testNoAsyncInit() {
        let core = DeduplicationCore(initialState: .init(count: 0))
        XCTAssertEqual(core.currentState.count, 0)
    }
}

// MARK: - Core tests

final class CoreEngineV2CoreTests: XCTestCase {

    private class TrackingCore: Core {
        enum Action { case increment, noChange }
        struct State: Equatable, Sendable { var count: Int }

        private(set) var setterCallCount = 0
        var state: State = .init(count: 0) {
            didSet { setterCallCount += 1 }
        }

        func reduce(state: State, action: Action) -> State {
            var s = state
            switch action {
            case .increment: s.count += 1
            case .noChange: break
            }
            return s
        }
    }

    /// State setter is not called when reduce returns an equal state.
    func testCoreDeduplication() {
        let core = TrackingCore()

        core.action(.increment)
        XCTAssertEqual(core.state.count, 1)
        XCTAssertEqual(core.setterCallCount, 1)

        core.action(.noChange)              // reduce returns same state
        XCTAssertEqual(core.state.count, 1)
        XCTAssertEqual(core.setterCallCount, 1)  // setter must NOT be called

        core.action(.increment)
        XCTAssertEqual(core.state.count, 2)
        XCTAssertEqual(core.setterCallCount, 2)
    }
}

// MARK: - PublisherCore tests

#if canImport(Combine)
import Combine

final class CoreEngineV2PublisherCoreTests: XCTestCase {

    private class TestPublisherCore: PublisherCore {
        var subscription: Set<AnyCancellable> = []

        enum Action { case increment, noChange }
        struct State: Equatable, Sendable { var count: Int }

        @Published var state: State = .init(count: 0)

        func reduce(state: State, action: Action) -> State {
            var s = state
            switch action {
            case .increment: s.count += 1
            case .noChange: break
            }
            return s
        }
    }

    /// PublisherCore does not emit when reduce returns an equal state.
    func testPublisherCoreDeduplication() {
        let core = TestPublisherCore()
        var received: [Int] = []

        core.$state
            .map(\.count)
            .sink { received.append($0) }
            .store(in: &core.subscription)

        core.action(.increment)   // 0 → 1, should emit
        core.action(.noChange)    // 1 → 1, should NOT emit
        core.action(.increment)   // 1 → 2, should emit

        // @Published emits initial value on subscription, then each change
        XCTAssertEqual(received, [0, 1, 2])
    }
}
#endif
