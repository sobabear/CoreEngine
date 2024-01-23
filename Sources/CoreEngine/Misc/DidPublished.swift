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

extension DidPublished where Value: Equatable {
    public static subscript<EnclosingSelf: ObservableObject>(
        _enclosingInstance instance: EnclosingSelf,
        wrapped wrappedKeyPath: ReferenceWritableKeyPath<EnclosingSelf, Value>,
        storage storageKeyPath: ReferenceWritableKeyPath<EnclosingSelf, DidPublished<Value>>
    ) -> Value {
        get {
            instance[keyPath: storageKeyPath].wrappedValue
        }
        set {
            (instance.objectWillChange as? ObservableObjectPublisher)?.send()
            instance[keyPath: storageKeyPath].wrappedValue = newValue
        }
    }
}
