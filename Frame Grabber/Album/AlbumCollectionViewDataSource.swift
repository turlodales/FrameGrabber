import UIKit
import Photos

class AlbumCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDataSourcePrefetching, PHPhotoLibraryChangeObserver {

    /// nil if deleted.
    private(set) var album: FetchedAlbum?

    var isEmpty: Bool {
        return album?.isEmpty ?? true
    }

    var albumDeletedHandler: (() -> ())?
    var albumChangedHandler: (() -> ())?
    var videosChangedHandler: ((PHFetchResultChangeDetails<PHAsset>) -> ())?

    var imageConfig: ImageConfig {
        didSet { imageManager.stopCachingImagesForAllAssets() }
    }

    private let cellProvider: (IndexPath, PHAsset) -> (UICollectionViewCell)
    private let photoLibrary: PHPhotoLibrary
    private let imageManager: PHCachingImageManager

    init(album: FetchedAlbum?,
         photoLibrary: PHPhotoLibrary = .shared(),
         imageManager: PHCachingImageManager = .init(),
         imageConfig: ImageConfig = .init(),
         cellProvider: @escaping (IndexPath, PHAsset) -> (UICollectionViewCell)) {

        self.album = album
        self.photoLibrary = photoLibrary
        self.imageManager = imageManager
        self.imageConfig = imageConfig
        self.cellProvider = cellProvider

        super.init()

        photoLibrary.register(self)
    }

    deinit {
        photoLibrary.unregisterChangeObserver(self)
        imageManager.stopCachingImagesForAllAssets()
    }

    /// Precondition: `album != nil`.
    func video(at indexPath: IndexPath) -> PHAsset {
        return album!.fetchResult.object(at: indexPath.item)
    }

    func thumbnail(for video: PHAsset, resultHandler: @escaping (UIImage?, ImageRequestInfo) -> ()) -> ImageRequest {
        return imageManager.requestImage(for: video, config: imageConfig, resultHandler: resultHandler)
    }

    private func safeVideos(at indexPaths: [IndexPath]) -> [PHAsset] {
        guard let fetchResult = album?.fetchResult else { return [] }
        let indexes = IndexSet(indexPaths.map { $0.item })
        let safeIndexes = indexes.filteredIndexSet { $0 < fetchResult.count }
        return fetchResult.objects(at: safeIndexes)
    }
}

extension AlbumCollectionViewDataSource {

    // MARK: UICollectionViewDataSource

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album?.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return cellProvider(indexPath, video(at: indexPath))
    }

    // MARK: UICollectionViewDataSourcePrefetching

    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        // Index paths might not exist anymore in the model.
        let videos = safeVideos(at: indexPaths)
        imageManager.startCachingImages(for: videos, targetSize: imageConfig.size, contentMode: imageConfig.mode, options: imageConfig.options)
    }

    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let videos = safeVideos(at: indexPaths)
        imageManager.stopCachingImages(for: videos, targetSize: imageConfig.size, contentMode: imageConfig.mode, options: imageConfig.options)
    }
}

// MARK: - PHPhotoLibraryChangeObserver

extension AlbumCollectionViewDataSource {

    func photoLibraryDidChange(_ change: PHChange) {
        DispatchQueue.main.async { [weak self] in
            self?.updateAlbum(with: change)
        }
    }

    private func updateAlbum(with change: PHChange) {
        guard let oldAlbum = album,
            let changeDetails = change.changeDetails(for: oldAlbum) else { return }

        self.album = changeDetails.albumAfterChanges

        guard !changeDetails.albumWasDeleted else {
            imageManager.stopCachingImagesForAllAssets()
            albumDeletedHandler?()
            return
        }

        if changeDetails.assetCollectionChanges != nil {
            albumChangedHandler?()
        }

        if let videoChange = changeDetails.fetchResultChanges {
            imageManager.stopCachingImagesForAllAssets()
            videosChangedHandler?(videoChange)
        }
    }
}
