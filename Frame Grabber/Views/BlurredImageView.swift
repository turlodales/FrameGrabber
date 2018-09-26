import UIKit

class BlurredImageView: UIView {

    let imageView = UIImageView()
    let visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))

    var image: UIImage? {
        get { return imageView.image }
        set { imageView.image = newValue }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }

    private func configureViews() {
        imageView.frame = bounds
        imageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        insertSubview(imageView, at: 0)

        visualEffectView.frame = bounds
        visualEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        insertSubview(visualEffectView, at: 1)
    }
}
