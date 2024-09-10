import Foundation
@testable import CoreEngine
import XCTest

actor MyAsyncCore: AsyncCore {
    
    var states: AsyncStream<State>
    var continuation: AsyncStream<State>.Continuation
    
    init(initialState: State) {
        self.currentState = initialState
        (self.states, self.continuation) = AsyncStream<State>.makeStream()
    }
    
    
    enum Action {
        case increment
        case decrement
    }
    
    struct State: Equatable {
        var count: Int
    }
    
    var currentState: State
    
    func reduce(state: State, action: Action) async throws -> State {
        var newState = state
        switch action {
        case .increment:
            newState.count += 1
        case .decrement:
            newState.count -= 1
        }
        
        return newState
    }
    
    func handleError(error: Error) async {
        print("Error: \(error.localizedDescription)")
    }
}

final class AsyncCoreTests: XCTestCase {

    

    // Test multiple actions in sequence
    func testMultipleActions() async {
        let core = MyAsyncCore(initialState: .init(count: 0))
        
        await core.action(.increment)
        await core.action(.increment)
        await core.action(.increment)
        
        var actionCount = 0
        
        for await count in await core.states.map(\.count) {
            actionCount += 1
            print("wow count is\(count)")
            if actionCount == 3 {
                break
            }
        }
    }
    
    func testMultipleSemd() {
        let core = MyAsyncCore(initialState: .init(count: 0))
        
        core.send(.increment)
        core.send(.increment)
        core.send(.increment)
        
        Task {
            var actionCount = 0
            for await count in await core.states.map(\.count) {
                actionCount += 1
                print("wow count is\(count)")
                if actionCount == 3 {
                    break
                }
            }
        }
    
    }
    
    func testCurrentValues() async {
        let core = MyAsyncCore(initialState: .init(count: 0))
        
        
        await core.action(.increment)
        let count1 = await core.currentState.count
        XCTAssertEqual(count1, 1)
        
        
        
        await core.action(.increment)
        let count2 = await core.currentState.count
        XCTAssertEqual(count2, 2)
        
        
        await core.action(.increment)
        let count3 = await core.currentState.count
        XCTAssertEqual(count3, 3)
        
        await core.action(.decrement)
        let count4 = await core.currentState.count
        XCTAssertEqual(count4, 2)
    }
}
