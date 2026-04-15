import Foundation
@testable import CoreEngine
import XCTest

actor MyAsyncCore: AsyncCore {
    let store: AsyncCoreStore<State>

    init(initialState: State) {
        self.store = .init(initialState: initialState)
    }

    enum Action: Sendable {
        case increment
        case decrement
    }

    struct State: Equatable, Sendable {
        var count: Int
    }

    func reduce(state: State, action: Action) async throws -> State {
        var newState = state
        switch action {
        case .increment: newState.count += 1
        case .decrement: newState.count -= 1
        }
        return newState
    }

    func handleError(error: Error) async {
        print("Error: \(error.localizedDescription)")
    }
}

final class AsyncCoreTests: XCTestCase {

    func testCurrentValues() async {
        let core = MyAsyncCore(initialState: .init(count: 0))

        var iter = core.states.makeAsyncIterator()
        let initial = await iter.next()
        XCTAssertEqual(initial?.count, 0)

        core.send(.increment)
        let after1 = await iter.next()
        XCTAssertEqual(after1?.count, 1)

        core.send(.increment)
        let after2 = await iter.next()
        XCTAssertEqual(after2?.count, 2)

        core.send(.decrement)
        let after3 = await iter.next()
        XCTAssertEqual(after3?.count, 1)
    }

    func testSendMultipleActions() async {
        let core = MyAsyncCore(initialState: .init(count: 0))

        var iter = core.states.makeAsyncIterator()
        _ = await iter.next() // consume initial replay

        core.send(.increment)
        core.send(.increment)
        core.send(.increment)

        var received: [Int] = []
        for _ in 0..<3 {
            if let state = await iter.next() {
                received.append(state.count)
            }
        }
        XCTAssertEqual(received, [1, 2, 3])
    }

    func testNonisolatedCurrentState() async {
        let core = MyAsyncCore(initialState: .init(count: 0))

        var iter = core.states.makeAsyncIterator()
        _ = await iter.next() // consume initial

        core.send(.increment)
        _ = await iter.next() // wait for state change

        // currentState is safe to read from any context
        XCTAssertEqual(core.currentState.count, 1)
    }
}
