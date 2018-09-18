import UIKit

class FrameThumbnailsCollectionViewLayout: UICollectionViewFlowLayout {

    init(lineSpacing: CGFloat = 2) {
        super.init()

        self.sectionInsetReference = .fromSafeArea
        self.scrollDirection = .horizontal
        self.minimumLineSpacing = lineSpacing
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()
        collectionView?.contentInsetAdjustmentBehavior = .always
        updateItemSize(for: collectionViewContentSize)
    }

    func updateItemSize(for boundingSize: CGSize) {
        let height = boundingSize.height
        let newSize = CGSize(width: height, height: height)

        if newSize != itemSize {
            itemSize = newSize
        }
    }
}
