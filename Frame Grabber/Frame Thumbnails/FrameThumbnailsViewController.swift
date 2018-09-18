import UIKit

protocol FrameThumbnailsViewControllerDelegate: class {
    func controller(_ controller: FrameThumbnailsViewController, didSelectFrame frame: Frame, atIndex index: Int)
}

class FrameThumbnailsViewController: UICollectionViewController {

    weak var delegate: FrameThumbnailsViewControllerDelegate?

    private(set) var frames = [Frame]()
    private let cellId = String(describing: FrameCell.self)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    private func configureViews() {
        collectionView.collectionViewLayout = FrameThumbnailsCollectionViewLayout()
    }

    // MARK: - Managing Frames

    func setFrames(_ frames: [Frame]) {
        self.frames = frames
        collectionView.reloadSections([0])
    }

     /// Frames are inserted in sorted order by time.
    func insertFrame(_ frame: Frame) {
        let index = frames.firstIndex { frame.time < $0.time } ?? frames.count
        frames.insert(frame, at: index)

        let indexPath = IndexPath(item: index, section: 0)
        collectionView.insertItems(at: [indexPath])
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    func removeFrame(at index: Int) {
        frames.remove(at: index)
        let index = IndexPath(item: index, section: 0)
        collectionView.deleteItems(at: [index])
    }

    var selectedIndex: Int? {
        return collectionView.indexPathsForSelectedItems?.first?.item
    }

    func clearSelection() {
        collectionView.selectItem(at: nil, animated: true, scrollPosition: .top)
    }

    // MARK: UICollectionViewDataSource/UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.controller(self, didSelectFrame: frames[indexPath.item], atIndex: indexPath.item)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frames.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? FrameCell else { fatalError("Wrong cell id or type.") }

        let frame = frames[indexPath.item]
        cell.imageView.image = frame.image

        return cell
    }
}
