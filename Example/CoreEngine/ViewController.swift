import UIKit
import Combine
import CoreEngine

class ViewController: UIViewController {
    var subscription = Set<AnyCancellable>()
    var core: MainCore = .init()
    
    
    @IBOutlet var label: UILabel!

    @IBAction func increaseAction() {
        self.core.action(.increase)
    }
    
    @IBAction func decreaseAction() {
        self.core.action(.decrease)
        
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bind(core: self.core)
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func bind(core: MainCore) {
        core.$state.map(\.count)
            .sink { [weak self] count in
                self?.label.text = "\(count)"
            }
            .store(in: &subscription)
    }

}

