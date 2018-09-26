import UIKit
import AVKit

protocol PlayerViewControllerDelegate: class {
    func controller(_ controller: PlayerViewController, loadingVideoDidFinish video: Video, playbackController: PlaybackController)
    func controllerLoadingVideoDidFail(_ controller: PlayerViewController)
    func controllerPlaybackDidFail(_ controller: PlayerViewController)
}

/// Loads the video and manages background, loading and player view.
class PlayerViewController: UIViewController {

    weak var delegate: PlayerViewControllerDelegate?
    private(set) var playbackController: PlaybackController?
    
    var videoManager: VideoManager? {
        didSet { loadMedia() }
    }

    private var isReadyForInitialPlayback = false {
        didSet { loadingView.imageView.isHidden = isReadyForInitialPlayback }
    }

    @IBOutlet var backgroundView: BlurredImageView!
    @IBOutlet var loadingView: PlayerLoadingView!
    @IBOutlet var playerView: ZoomingPlayerView!

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        loadMedia()
    }
}

private extension PlayerViewController {

    func configureViews() {
        view.backgroundColor = nil
        playerView.delegate = self
        updateReadyForInitialPlayback()
    }

    func loadMedia() {
        guard isViewLoaded else { return }
        loadPreviewImage()
        loadVideo()
    }

    func loadPreviewImage() {
        let size = loadingView.imageView.bounds.size.scaledToScreen
        let config = ImageConfig(size: size, mode: .aspectFit, options: .default())

        videoManager?.loadPosterImage(with: config) { [weak self] image, _ in
            guard let image = image else { return }

            // Use same image for background ignoring different size/content mode as it's
            // blurred anyway.
            self?.loadingView.imageView.image = image
            self?.backgroundView.imageView.image = image
        }
    }

    func loadVideo() {
        videoManager?.loadVideo(progressHandler: { [weak self] progress in
            self?.loadingView.showProgress(Float(progress), animated: true)

        }, resultHandler: { [weak self] video, info in
            self?.loadingView.showProgress(nil, animated: true)

            if !info.isCancelled {
                self?.configurePlayback(with: video)
            }
        })
    }

    func configurePlayback(with video: Video?) {
        guard let video = video else {
            delegate?.controllerLoadingVideoDidFail(self)
            return
        }

        playbackController = PlaybackController(video: video)
        playbackController?.observers.add(self)
        playerView.player = playbackController?.player
        playbackController?.play()

        delegate?.controller(self, loadingVideoDidFinish: video, playbackController: playbackController!)
    }

    func updateReadyForInitialPlayback() {
        let isReady = (playbackController?.isReadyToPlay ?? false) && playerView.isReadyForDisplay

        // Player, item and view will reset their readiness on loops. Hide preview image
        // when all have been initially ready but not on later loops.
        isReadyForInitialPlayback = isReadyForInitialPlayback || isReady
    }
}

// MARK: - ZoomingPlayerViewDelegate

extension PlayerViewController: ZoomingPlayerViewDelegate {

    func playerView(_ playerView: ZoomingPlayerView, didUpdateReadyForDisplay ready: Bool) {
        updateReadyForInitialPlayback()
    }
}

// MARK: - PlayerObserver

extension PlayerViewController: PlayerObserver {

    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status) {
        if status == .failed {
            delegate?.controllerPlaybackDidFail(self)
        }

        updateReadyForInitialPlayback()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {
        if status == .failed {
            delegate?.controllerPlaybackDidFail(self)
        }
        
        updateReadyForInitialPlayback()
    }
}

// MARK: - Transition

extension PlayerViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        playerView.isHidden = true
        loadingView.isHidden = true
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        playerView.isHidden = false
        loadingView.isHidden = false
        updateReadyForInitialPlayback()  // Show/hide preview image for current readiness.
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        return loadingView.imageView.image
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        guard let playerView = playerView else { return nil }

        // If ready animate from video position (possibly zoomed, scrolled), otherwise
        // from preview image (centered, aspect fitted). Or fall back to cross-dissolve.
        guard let sourceFrame = playerView.zoomedVideoFrame.nonZeroSize ?? loadingImageFrame.nonZeroSize else {
            return nil
        }

        return view.convert(sourceFrame, to: view)
    }

    /// The aspect fitted size the preview image occupies in the image view.
    private var loadingImageFrame: CGRect {
        guard let image = loadingView.imageView.image else { return .zero }
        return AVMakeRect(aspectRatio: image.size, insideRect: loadingView.imageView.frame)
    }
}

private extension CGRect {
    var nonZeroSize: CGRect? {
        return (size == .zero) ? nil : self
    }
}
