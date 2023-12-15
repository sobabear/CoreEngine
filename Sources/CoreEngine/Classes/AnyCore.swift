import Foundation
import Combine

public protocol AnyCore: Core {
    typealias Error = Swift.Error
    
    var subscription: Set<AnyCancellable> { get set }
    func dispatch(effect: any Publisher<Action, Error>)
    func dispatch(effect: any Publisher<Action, Never>)
    
    func handleError(error: Error)
}

extension AnyCore {
    /// Dispatches an effect represented by an `Publisher` of `Action`.
    /// This function handles both emitting values and errors.
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
    
    /// Dispatches an effect represented by an `AsyncStream` of `Action`.
    /// This function handles both emitting values and errors.
    public func dispatch(effect: AsyncStream<Action>) {
        Task {
            for await action in effect {
                self.state = self.reduce(state: self.state, action: action)
            }
        }
    }

    /// Dispatches an effect represented by an `AsyncThrowingStream` of `Action`.
    /// This function handles both emitting values and catching errors.
    public func dispatch(effect: AsyncThrowingStream<Action, Error>) {
        Task {
            do {
                for try await action in effect {
                    self.state = self.reduce(state: self.state, action: action)
                }
            } catch {
                self.handleError(error: error)
            }
        }
    }
    
    public func handleError(error: Error) { }
}
