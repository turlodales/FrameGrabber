import UIKit

class GradientView: PassThroughView {

    override static var layerClass: AnyClass {
        return CAGradientLayer.self
    }

    var gradientLayer: CAGradientLayer {
        return layer as! CAGradientLayer
    }

    var colors: [UIColor] {
        get {
            let colors = (gradientLayer.colors as? [CGColor]) ?? []
            return colors.map(UIColor.init)
        }
        set { gradientLayer.colors = newValue.map { $0.cgColor } }
    }
}
