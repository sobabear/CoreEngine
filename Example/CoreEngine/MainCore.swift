import Foundation
import Combine
import CoreEngine

class MainCore: Core {
    var subscription: Set<AnyCancellable> = .init()
    
    enum Action: Equatable, Hashable {
        case increase
        case decrease
    }
    
    struct State: Equatable {
        var count = 0
    }

    @Published var state: State = .init()

    func mutate(state: State, action: Action) -> State {
        var newState = state
        switch action {
        case .decrease:
            newState.count -= 1
        case .increase:
            newState.count += 1
        }
        return newState
    }
}
