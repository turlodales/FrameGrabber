import UIKit

class SpinnerViewController: UIViewController {

    static func instantiateFromStoryboard() -> SpinnerViewController {
        let id = String(describing: SpinnerViewController.self)
        let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: id)
        controller.modalPresentationStyle = .overCurrentContext
        controller.modalTransitionStyle = .crossDissolve
        return controller as! SpinnerViewController
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
