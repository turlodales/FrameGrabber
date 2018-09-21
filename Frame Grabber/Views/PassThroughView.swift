import UIKit

class PassThroughView: UIView {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        let passThrough = (hitView == self) || (hitView is UIStackView)
        return passThrough ? nil : hitView
    }
}
