import AVKit
import Photos

class VideoManager {

    let asset: PHAsset

    private let imageManager: PHImageManager
    private(set) var imageRequest: ImageRequest?
    private(set) var videoRequest: ImageRequest?

    init(asset: PHAsset, imageManager: PHImageManager = .default()) {
        self.asset = asset
        self.imageManager = imageManager
    }

    deinit {
        cancelAllRequests()
    }

    func cancelAllRequests() {
        imageRequest = nil
        videoRequest = nil
    }

    /// Pending requests of this type are cancelled.
    /// The result handler is called asynchronously on the main thread.
    func loadPosterImage(with config: ImageConfig, resultHandler: @escaping (UIImage?, PHImageManager.Info) -> ()) {
        imageRequest = imageManager.requestImage(for: asset, config: config, resultHandler: resultHandler)
    }

    /// Pending requests of this type are cancelled.
    /// If available, the item is served directly, otherwise downloaded from iCloud.
    /// Handlers are called asynchronously on the main thread.
    func loadVideo(withOptions options: PHVideoRequestOptions? = .default(), progressHandler: @escaping (Double) -> (), resultHandler: @escaping (Video?, PHImageManager.Info) -> ()) {
        videoRequest = imageManager.requestAVAsset(for: asset, options: options, progressHandler: progressHandler) { [weak self] avAsset, _, info in
            guard let asset = self?.asset, let avAsset = avAsset else {
                resultHandler(nil, info)
                return
            }
            
            resultHandler(Video(asset: asset, avAsset: avAsset), info)
        }
    }
}
