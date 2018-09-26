import UIKit
import CoreMedia

protocol FrameThumbnailsViewControllerDelegate: class {
    func controllerThumbnailsChanged(_ controller: FrameThumbnailsViewController)
    func controllerSelectionChanged(_ controller: FrameThumbnailsViewController)
}

class FrameThumbnailsViewController: UICollectionViewController {

    weak var delegate: FrameThumbnailsViewControllerDelegate?

    var video: Video? {
        didSet {
            dataSource = video.flatMap { FramesDataSource(video: $0) }
            dataSource?.thumbnailSize = thumbnailSize
        }
    }

    var thumbnails: [Frame] {
        return dataSource?.thumbnails ?? []
    }

    var selectedThumbnail: Frame? {
        let index = collectionView.indexPathsForSelectedItems?.first?.item
        return index.flatMap { dataSource?.thumbnails[$0] }
    }

    private var dataSource: FramesDataSource?
    private let cellId = String(describing: FrameCell.self)

    private var thumbnailSize: CGSize {
        return (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize ?? .zero
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    private func configureViews() {
        collectionView.collectionViewLayout = FrameThumbnailsCollectionViewLayout()
    }

    // MARK: - Frames

    /// Frames are inserted in sorted order by time.
    func addThumbnail(for time: CMTime) {
        dataSource?.addThumbnail(for: time) { [weak self] index, result in
            guard let self = self, let index = index else { return }
            let indexPath = IndexPath(item: index, section: 0)
            self.collectionView.insertItems(at: [indexPath])
            self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
            self.delegate?.controllerThumbnailsChanged(self)
        }
    }

    func removeThumbnail(at index: Int) {
        clearSelection()
        dataSource?.removeThumbnail(at: index)
        collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
        delegate?.controllerThumbnailsChanged(self)
    }

    @IBAction private func removeThumbnail(_ sender: UIButton) {
        guard let cell = sender.firstSuperview(of: UICollectionViewCell.self),
            let indexPath = collectionView.indexPath(for: cell) else { return }

        removeThumbnail(at: indexPath.item)
    }

    func generateFullSizeFrames(for times: [CMTime], completionHandler: @escaping (FramesResult) -> ()) {
        dataSource?.generateFullSizeFrames(for: times, completionHandler: completionHandler)
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
        return dataSource?.thumbnails.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? FrameCell else { fatalError("Wrong cell id or type.") }

        cell.imageView.image = dataSource?.thumbnails[indexPath.item].image.image

        return cell
    }
}

private extension UIView {
    func firstSuperview<T>(of type: T.Type) -> T? {
        return (superview as? T)
            ?? superview?.firstSuperview(of: T.self)
    }
}
