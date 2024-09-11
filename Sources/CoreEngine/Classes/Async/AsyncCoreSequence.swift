import Foundation

@dynamicMemberLookup
public final class AsyncCoreSequence<State>: AsyncSequence {
    public typealias Element = State
    public struct Iterator: AsyncIteratorProtocol {
        public typealias Element = State

        @usableFromInline
        var iterator: AsyncStream<Element>.Iterator

        @usableFromInline
        init(_ iterator: AsyncStream<Element>.Iterator) {
            self.iterator = iterator
        }

        @inlinable
        public mutating func next() async -> Element? {
            await iterator.next()
        }
    }
    
    private let stream: AsyncStream<State>
    private var continuations: [AsyncStream<State>.Continuation] = []
    private var last: State?
    
    public init(_ stream: AsyncStream<State>) {
        self.stream = stream
    }
    
    deinit {
        continuations.forEach { $0.finish() }
    }
    
    public nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(stream.makeAsyncIterator())
    }
    
    public func send(_ state: State) {
        last = state
        for continuation in continuations {
            continuation.yield(state)
        }
    }

    public subscript<Property>(
        dynamicMember keyPath: KeyPath<State, Property>
    ) -> AsyncMapSequence<AsyncStream<State>, Property> {
        let (stream, continuation) = AsyncStream<Element>.createStream()
        continuations.append(continuation)
        if let last {
            continuation.yield(last)
        }
        return stream.map { $0[keyPath: keyPath] }
    }
}

public extension AsyncCoreSequence {
    /// Custom `map` function to map over state properties using key paths.
    func map<Property>(
        _ keyPath: KeyPath<State, Property>
    ) -> AsyncMapSequence<AsyncStream<State>, Property> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        
        if let lastState = last {
            continuation.yield(lastState)
        }
        
        return stream.map { $0[keyPath: keyPath] }
    }
    
    func map<Transformed>(
        _ transform: @Sendable @escaping (State) async -> Transformed
    ) -> AsyncMapSequence<AsyncStream<State>, Transformed> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.map(transform)
    }
    
    func map<Transformed>(
        _ transform: @escaping (State) async throws -> Transformed
    ) -> AsyncThrowingMapSequence<AsyncStream<State>, Transformed> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.map(transform)
    }
    
    func filter(
        _ isIncluded: @escaping (State) async -> Bool
    ) -> AsyncFilterSequence<AsyncStream<State>> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.filter(isIncluded)
    }
    
    func dropFirst(_ count: Int = 1) -> AsyncDropFirstSequence<AsyncStream<State>> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.dropFirst(count)
    }
    
    func flatMap<SegmentOfResult: AsyncSequence>(
        _ transform: @escaping (State) async -> SegmentOfResult
    ) -> AsyncFlatMapSequence<AsyncStream<State>, SegmentOfResult> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.flatMap(transform)
    }
    
    func flatMap<SegmentOfResult: AsyncSequence>(
        _ transform: @escaping (State) async throws -> SegmentOfResult
    ) -> AsyncThrowingFlatMapSequence<AsyncStream<State>, SegmentOfResult> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.flatMap(transform)
    }

    func drop(
        while predicate: @escaping (State) async -> Bool
    ) -> AsyncDropWhileSequence<AsyncStream<State>> {
        let (stream, continuation) = AsyncStream<State>.createStream()
        continuations.append(continuation)
        if let last = last {
            continuation.yield(last)
        }
        return stream.drop(while: predicate)
    }
}


extension AsyncSequence {
    /// makeStream is not supported on Linux
    static func createStream(
        of elementType: Element.Type = Element.self,
        bufferingPolicy limit: AsyncStream<Element>.Continuation.BufferingPolicy = .unbounded
    ) -> (stream: AsyncStream<Element>, continuation: AsyncStream<Element>.Continuation) {
        var continuation: AsyncStream<Element>.Continuation!
        let stream = AsyncStream<Element>(bufferingPolicy: limit) { cont in
            continuation = cont
        }
        return (stream, continuation)
    }
}
