import UIKit
import AVKit
import Photos

protocol PlayerLoadingViewControllerDelegate: class {
    func controller(_ controller: PlayerLoadingViewController, didFinishLoadingPreviewImage image: UIImage)
    func controller(_ controller: PlayerLoadingViewController, didFinishLoadingVideo video: Video)
    func controllerLoadingVideoDidFail(_ controller: PlayerLoadingViewController)
}

class PlayerLoadingViewController: UIViewController {

    weak var delegate: PlayerLoadingViewControllerDelegate?

    var videoAsset: PHAsset! {
        didSet { loadMedia() }
    }

    private lazy var imageManager: PHImageManager = .default()
    private var imageRequest: ImageRequest?
    private var videoRequest: ImageRequest?

    @IBOutlet var loadingView: PlayerLoadingView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadMedia()
    }
}

private extension PlayerLoadingViewController {

    func configureViews() {
        view.backgroundColor = nil
        loadingView.backgroundColor = nil
    }

    func loadMedia() {
        guard isViewLoaded else { return }
        loadPreviewImage()
        loadVideo()
    }

    func loadPreviewImage() {
        let size = loadingView.imageView.bounds.size.scaledToScreen
        let config = ImageConfig(size: size, mode: .aspectFit, options: .default())

        imageRequest = imageManager.requestImage(for: videoAsset, config: config) { [weak self] image, _ in
            guard let self = self, let image = image else { return }
            self.loadingView.imageView.image = image
            self.delegate?.controller(self, didFinishLoadingPreviewImage: image)
        }
    }

    func loadVideo() {
        videoRequest = imageManager.requestAVAsset(for: videoAsset, options: .default(), progressHandler: { [weak self] progress in
            self?.loadingView.showProgress(Float(progress), animated: true)
        }, resultHandler: { [weak self] avAsset, _, info in
            self?.loadingView.showProgress(nil, animated: false)
            self?.handleVideoResult(with: avAsset, info: info)
        })
    }

    func handleVideoResult(with avAsset: AVAsset?, info: ImageRequestInfo) {
        guard !info.isCancelled else { return }

        guard let avAsset = avAsset else {
            delegate?.controllerLoadingVideoDidFail(self)
            return
        }

        let video = Video(asset: videoAsset, avAsset: avAsset)
        delegate?.controller(self, didFinishLoadingVideo: video)
    }
}

// MARK: - Transition

extension PlayerLoadingViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        loadingView.isHidden = true
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        loadingView.isHidden = false
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        return loadingView.imageView.image
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        let frame = loadingImageFrame
        return (frame.size != .zero) ? view.convert(frame, to: view) : nil
    }

    /// The aspect fitted size the preview image occupies in the image view.
    private var loadingImageFrame: CGRect {
        guard let image = loadingView.imageView.image else { return .zero }
        return AVMakeRect(aspectRatio: image.size, insideRect: loadingView.imageView.frame)
    }
}
