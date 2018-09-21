import UIKit
import Photos

class AlbumViewController: UICollectionViewController {

    // nil if deleted.
    var album: FetchedAlbum? {
        get { return dataSource?.album }
        set { configureDataSource(with: newValue) }
    }

    private var dataSource: AlbumCollectionViewDataSource!
    private lazy var transitionController = ZoomTransitionController()

    @IBOutlet private var emptyView: UIView!

    private lazy var durationFormatter = VideoDurationFormatter()
    private let cellId = String(describing: VideoCell.self)

    // MARK: Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        updateThumbnailSize()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? PlayerContainerController {
            prepareForPlayerSegue(with: controller)
        }
    }

    private func prepareForPlayerSegue(with destination: PlayerContainerController) {
        guard let selectedIndexPath = collectionView?.indexPathsForSelectedItems?.first else { fatalError("Segue without selection or asset") }

        transitionController.prepareTransition(forSource: self, destination: destination)

        let selectedAsset = dataSource.video(at: selectedIndexPath)
        destination.videoManager = VideoManager(asset: selectedAsset)
    }
}

// MARK: - UICollectionViewDelegate

extension AlbumViewController {

    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let cell = cell as? VideoCell else { return }
        cell.imageRequest = nil
    }
}

// MARK: - Private

private extension AlbumViewController {

    func configureViews() {
        clearsSelectionOnViewWillAppear = false
        collectionView?.alwaysBounceVertical = true
        collectionView?.collectionViewLayout = CollectionViewGridLayout()
    }

    func configureDataSource(with album: FetchedAlbum?) {
        dataSource = AlbumCollectionViewDataSource(album: album) { [unowned self] in
            self.cell(for: $1, at: $0)
        }

        dataSource.albumDeletedHandler = { [weak self] in
            // Just show empty screen.
            self?.updateAlbumData()
            self?.collectionView?.reloadData()
        }

        dataSource.albumChangedHandler = { [weak self] in
            self?.updateAlbumData()
        }

        dataSource.videosChangedHandler = { [weak self] changeDetails in
            self?.updateAlbumData()

            self?.collectionView?.applyPhotoLibraryChanges(for: changeDetails, cellConfigurator: { 
                self?.reconfigure(cellAt: $0)
            })
        }

        collectionView?.isPrefetchingEnabled = true
        collectionView?.dataSource = dataSource
        collectionView?.prefetchDataSource = dataSource

        updateAlbumData()
        updateThumbnailSize()
    }

    func updateAlbumData() {
        title = dataSource?.album?.title ?? ""  // Won't accept nil.
        collectionView?.backgroundView = dataSource.isEmpty ? emptyView : nil
    }

    func updateThumbnailSize() {
        guard let layout = collectionView?.collectionViewLayout as? CollectionViewGridLayout else { return }
        dataSource.imageConfig.size = layout.itemSize.scaledToScreen
    }

    func cell(for video: PHAsset, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as? VideoCell else { fatalError("Wrong cell identifier or type.") }
        configure(cell: cell, for: video)
        return cell
    }

    func configure(cell: VideoCell, for video: PHAsset) {
        cell.durationLabel.text = durationFormatter.string(from: video.duration)
        cell.favoritedImageView.isHidden = !video.isFavorite
        loadThumbnail(for: cell, video: video)
    }

    func reconfigure(cellAt indexPath: IndexPath) {
        guard let cell = collectionView?.cellForItem(at: indexPath) as? VideoCell else { return }
        let video = dataSource.video(at: indexPath)
        configure(cell: cell, for: video)
    }

    func loadThumbnail(for cell: VideoCell, video: PHAsset) {
        cell.identifier = video.localIdentifier

        cell.imageRequest = dataSource.thumbnail(for: video) { image, _ in
            let isCellRecycled = cell.identifier != video.localIdentifier

            guard !isCellRecycled, let image = image else { return }

            cell.imageView.image = image
        }
    }
}
