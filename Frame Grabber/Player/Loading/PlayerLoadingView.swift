import UIKit

class PlayerLoadingView: PassThroughView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var progressView: UIProgressView!
    @IBOutlet var imageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    func showProgress(_ progress: Float?, animated: Bool) {
        let shouldHide = progress == nil
        progressView.setProgress(progress ?? 0, animated: animated)
        progressView.setHidden(shouldHide, animated: animated)
        titleLabel.setHidden(shouldHide, animated: animated)
    }

    private func configureViews() {
        titleLabel.applyOverlayShadow()
        progressView.applyOverlayShadow()
        progressView.trackTintColor = .white
        progressView.layer.cornerRadius = 4
        progressView.layer.masksToBounds = true
        showProgress(nil, animated: false)
    }
}
