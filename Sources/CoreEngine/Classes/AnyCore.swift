import Foundation
#if canImport(Combine)
import Combine

public protocol AnyCore: Core, ObservableObject {
    typealias Error = Swift.Error
    
    var subscription: Set<AnyCancellable> { get set }
    func dispatch(effect: any Publisher<Action, Error>)
    func dispatch(effect: any Publisher<Action, Never>)
    
    func handleError(error: Error)
}

extension AnyCore {
    public func dispatch(effect: any Publisher<Action, Error>) {
        effect
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.handleError(error: error)
                }
            } receiveValue: { [weak self] value in
                if let self {
                    self.state = self.reduce(state: self.state, action: value)
                }
            }
            .store(in: &self.subscription)
    }
    
    public func dispatch(effect: any Publisher<Action, Never>) {
        effect
            .sink(receiveValue: { [weak self] value in
                if let self {
                    self.state = self.reduce(state: self.state, action: value)
                }
            })
            .store(in: &self.subscription)
    }
    
    public func handleError(error: Error) { }
}
#endif
