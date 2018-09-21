import UIKit

class FrameCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    var selectionView = UIView()

    override func awakeFromNib() {
        super.awakeFromNib()
        configureViews()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }

    override var isSelected: Bool {
        didSet { selectionView.setHidden(!isSelected, animated: true) }
    }

    private func configureViews() {
        selectionView.isHidden = true
        selectionView.frame = bounds
        selectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        selectionView.backgroundColor = nil
        selectionView.layer.borderColor = UIColor.white.cgColor
        selectionView.layer.borderWidth = 2
        addSubview(selectionView)
    }
}
