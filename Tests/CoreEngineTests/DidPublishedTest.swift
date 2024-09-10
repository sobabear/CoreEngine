import XCTest
#if canImport(Combine)
import Combine

//@testable import YourModuleName  // Replace with the name of your module
@testable import CoreEngine

class DidPublishedTests: XCTestCase {
    var cancellables: Set<AnyCancellable> = []
    
    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }
    
    // Test to verify that the wrapped value changes correctly
    func testWrappedValueAssignment() {
        class TestObject {
            @DidPublished var value: Int = 0
        }
        
        let testObject = TestObject()
        XCTAssertEqual(testObject.value, 0)
        
        testObject.value = 10
        XCTAssertEqual(testObject.value, 10)
    }
    
    // Test to verify that the publisher emits values when the wrapped value changes
    func testPublisherEmitsValues() {
        class TestObject {
            @DidPublished var value: String = "Initial"
        }
        
        let testObject = TestObject()
        var receivedValues: [String] = []
        
        testObject.$value
            .sink { value in
                receivedValues.append(value)
            }
            .store(in: &cancellables)
        
        testObject.value = "First Update"
        testObject.value = "Second Update"
        
        // Allow some time for the publisher to emit values
        XCTAssertEqual(receivedValues, ["First Update", "Second Update"])
    }
    
    // Test to verify that ObservableObject integration works
    func testObservableObjectIntegration() async {
        class TestObject: ObservableObject {
            @DidPublished var value: Double = 0.0
        }
        
        let objectWillChangedExpectation = XCTestExpectation(description: "DidCalled object will changed")
        let valuePublisherExpectation = XCTestExpectation(description: "value was changed")
        
        let testObject = TestObject()
        
        
        testObject.$value
            .sink { _ in
                valuePublisherExpectation.fulfill()
            }
            .store(in: &cancellables)
        
        testObject.value = 3.14
        
        await fulfillment(of: [ valuePublisherExpectation], timeout: 5)
        
        
        XCTAssertEqual(testObject.value, 3.14)
    }
}
#endif