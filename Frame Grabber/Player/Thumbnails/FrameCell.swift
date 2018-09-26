import UIKit

class FrameCell: UICollectionViewCell {

    @IBOutlet var imageView: UIImageView!
    @IBOutlet var deleteButton: UIButton!
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
        didSet {
            deleteButton.setHidden(!isSelected, animated: true)
        }
    }

    private func configureViews() {
        deleteButton.isHidden = true
        deleteButton.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        deleteButton.applyOverlayShadow()
    }
}
