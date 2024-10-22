import Foundation
@testable import CoreEngine
import XCTest

actor MyAsyncCore: @preconcurrency AsyncCore {
    
  var states: AsyncCoreSequence<State>
    var continuation: AsyncStream<State>.Continuation
    
    init(initialState: State) {
        self.currentState = initialState
      let (stream, continuation) = AsyncStream<State>.makeStream()
      
      self.states = .init(stream)
      self.continuation = continuation
    }
    
    
    enum Action {
        case increment
        case decrement
        case sleepAndIncreaseTen
    }
    
    struct State: Equatable {
        var count: Int
    }
    
  nonisolated(unsafe) var currentState: State
    
    func reduce(state: State, action: Action) async throws -> State {
        var newState = state
        switch action {
        case .increment:
            newState.count += 1
        case .decrement:
            newState.count -= 1
        case .sleepAndIncreaseTen:
          try! await Task.sleep(nanoseconds: 1_000_000_000)
          newState.count += 10
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
        let count1 = core.currentState.count
        XCTAssertEqual(count1, 1)
        
        
        
        await core.action(.increment)
        let count2 = core.currentState.count
        XCTAssertEqual(count2, 2)
        
        
        await core.action(.increment)
        let count3 = core.currentState.count
        XCTAssertEqual(count3, 3)
        
        await core.action(.decrement)
        let count4 = core.currentState.count
        XCTAssertEqual(count4, 2)
    }
  
  func testEstimateTime() async {
    let core = MyAsyncCore(initialState: .init(count: 0))
    let startTime = Date().timeIntervalSince1970
    
    await core.action(.sleepAndIncreaseTen)
    await core.action(.sleepAndIncreaseTen)
    await core.action(.sleepAndIncreaseTen)
    await core.action(.decrement)

    await core.action(.sleepAndIncreaseTen)

    
    let endTime = Date().timeIntervalSince1970
    
    XCTAssertLessThanOrEqual(endTime - startTime, 5)
    XCTAssertEqual(core.currentState.count, 39)
    
  }
}
