import Foundation
import Combine

public protocol CoreBindable: AnyObject {
    associatedtype Core: CoreEngine.Core
    var core: Core? { get set }
    var subscription: Set<AnyCancellable> { get set }
    func bind(core: Core)
}

extension CoreBindable {
    public var core: Core? {
        get { return objc_getAssociatedObject(self.self, &AssociatedKeys.core) as? Core }
        set(newCore) {
            if let core = newCore {
                objc_setAssociatedObject(self.self, &AssociatedKeys.core, core, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                self.subscription.forEach({ $0.cancel() })
                self.subscription = .init()
                bind(core: core)
            }
            
        }
    }
}


internal struct AssociatedKeys {
    static var core = "Core"
}
