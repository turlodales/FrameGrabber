import UIKit

class PlayerTitleView: GradientView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var dimensionsLabel: UILabel!
    @IBOutlet var frameRateLabel: UILabel!
    @IBOutlet var subtitleContainer: UIStackView!
    @IBOutlet var thumbnailsContainer: UIView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    private func configureViews() {
        colors = Style.Color.overlayTopGradient
        applyOverlayShadow()
        titleLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 18, weight: .bold)
    }
}
