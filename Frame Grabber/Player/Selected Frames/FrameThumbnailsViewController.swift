import UIKit

protocol FrameThumbnailsViewControllerDelegate: class {
    func controllerSelectionChanged(_ controller: FrameThumbnailsViewController)
    func controllerFramesChanged(_ controller: FrameThumbnailsViewController)
}

class FrameThumbnailsViewController: UICollectionViewController {

    weak var delegate: FrameThumbnailsViewControllerDelegate?

    private(set) var frames = [Frame]() {
        didSet { delegate?.controllerFramesChanged(self) }
    }

    var selectedFrame: Frame? {
        return collectionView.indexPathsForSelectedItems?.first.flatMap { frames[$0.item] }
    }

    private let cellId = String(describing: FrameCell.self)

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    private func configureViews() {
        collectionView.collectionViewLayout = FrameThumbnailsCollectionViewLayout()
    }

    // MARK: - Managing Frames

     /// Frames are inserted in sorted order by time.
    func insertFrame(_ frame: Frame) {
        let index = frames.firstIndex { frame.time < $0.time } ?? frames.count
        frames.insert(frame, at: index)

        let indexPath = IndexPath(item: index, section: 0)
        collectionView.insertItems(at: [indexPath])
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
    }

    @IBAction func removeFrame(_ sender: UIButton) {
        guard let cell = sender.firstSuperview(of: UICollectionViewCell.self),
            let indexPath = collectionView.indexPath(for: cell) else { return }

        clearSelection()
        frames.remove(at: indexPath.item)
        collectionView.deleteItems(at: [indexPath])
    }

    func clearSelection() {
        collectionView.selectItem(at: nil, animated: true, scrollPosition: .top)
        delegate?.controllerSelectionChanged(self)
    }

    // MARK: UICollectionViewDataSource/UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.controllerSelectionChanged(self)
    }

    override func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        delegate?.controllerSelectionChanged(self)
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

private extension UIView {
    func firstSuperview<T>(of type: T.Type) -> T? {
        return (superview as? T)
            ?? superview?.firstSuperview(of: T.self)
    }
}
