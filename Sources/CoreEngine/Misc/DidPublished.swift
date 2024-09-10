#if canImport(Combine)
import Combine

@propertyWrapper
public struct DidPublished<Value> {
    private var value: Value
    private let subject = PassthroughSubject<Value, Never>()

    public var wrappedValue: Value {
        get { value }
        set {
            value = newValue
            subject.send(newValue)
        }
    }

    public var projectedValue: AnyPublisher<Value, Never> {
        subject.eraseToAnyPublisher()
    }

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }
}
#endif
