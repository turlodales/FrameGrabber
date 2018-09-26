import UIKit
import AVKit

protocol PlayerViewControllerDelegate: class {
    func controllerIsReadyForInitialPlayback(_ controller: PlayerViewController)
    func controllerPlaybackDidFail(_ controller: PlayerViewController)
    func controllerDidSelectDone(_ controller: PlayerViewController)
    func controller(_ controller: PlayerViewController, didSelectShareFrames frames: [Frame])
    func controllerGeneratingFramesDidFail(_ controller: PlayerViewController)
}

/// Manages the title and player controls view, video playback and generating frames.
class PlayerViewController: UIViewController {

    weak var delegate: PlayerViewControllerDelegate?

    var video: Video! {
        didSet {
            playbackController = PlaybackController(video: video)
            playbackController.observers.add(self)
            playerView.player = playbackController.player
            thumbnailsViewController.video = video
            playbackController.play()
        }
    }

    private var playbackController: PlaybackController!
    private(set) var thumbnailsViewController: FrameThumbnailsViewController!
    private lazy var timeFormatter = VideoTimeFormatter()
    private var isReadyForInitialPlayback = false

    @IBOutlet var playerView: ZoomingPlayerView!
    @IBOutlet private var titleView: PlayerTitleView!
    @IBOutlet private var controlsView: PlayerControlsView!

    private var isScrubbing: Bool {
        return controlsView.timeSlider.isInteracting
    }

    private var isSeeking: Bool {
        return playbackController?.isSeeking ?? false
    }

    private var selectedFrames: [Frame] {
        return thumbnailsViewController.thumbnails
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? FrameThumbnailsViewController {
            thumbnailsViewController = controller
            thumbnailsViewController.delegate = self
        }
    }

    func toggleOverlays(animated: Bool = true) {
        titleView.toggleHidden(animated: animated)
        controlsView.toggleHidden(animated: animated)
    }
}

// MARK: - Actions

private extension PlayerViewController {

    @IBAction func done() {
        playbackController?.pause()
        delegate?.controllerDidSelectDone(self)
    }

    @IBAction func playOrPause() {
        guard !isScrubbing else { return }

        playbackController.playOrPause()
        thumbnailsViewController.clearSelection()
    }

    func step(byCount count: Int) {
        guard !isScrubbing else { return }

        playbackController.step(byCount: count)
        thumbnailsViewController.clearSelection()
    }

    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController.seeker.smoothlySeek(to: sender.time)
        // When scrubbing, display slider time instead of player time.
        updateViews(withTime: sender.time)
        thumbnailsViewController.clearSelection()
    }

    @IBAction func addCurrentFrame() {
        thumbnailsViewController.addThumbnail(for: playbackController.currentTime)
    }

    @IBAction func shareFrames() {
        playbackController.pause()

        let times = selectedFrames.isEmpty ? [playbackController.currentTime] : selectedFrames.map { $0.actualTime }
        generateFramesAndShare(for: times)
    }

    func generateFramesAndShare(for times: [CMTime]) {
        thumbnailsViewController.generateFullSizeFrames(for: times) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .cancelled:
                break
            case .failed:
                self.delegate?.controllerGeneratingFramesDidFail(self)
            case .succeeded(let frames):
                self.delegate?.controller(self, didSelectShareFrames: frames)
            }
        }
    }

    func showFrame(_ frame: Frame) {
        guard !isScrubbing else { return }

        playbackController.pause()
        playbackController.seeker.smoothlySeek(to: frame.actualTime)
    }
}

// MARK: - FrameThumbnailsViewControllerDelegate

extension PlayerViewController: FrameThumbnailsViewControllerDelegate {

    func controllerSelectionChanged(_ controller: FrameThumbnailsViewController) {
        if let frame = thumbnailsViewController.selectedThumbnail {
            showFrame(frame)
        }

        updateFrameSelection()
    }

    func controllerThumbnailsChanged(_ controller: FrameThumbnailsViewController) {
        updateFrameSelection()
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
        updateControlsEnabled()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {
        if status == .failed {
            delegate?.controllerPlaybackDidFail(self)
        }

        updateReadyForInitialPlayback()
        updateControlsEnabled()
    }

    func player(_ player: AVPlayer, didPeriodicUpdateAtTime time: CMTime) {
        updateViews(withTime: time)
    }

    func player(_ player: AVPlayer, didUpdateTimeControlStatus status: AVPlayer.TimeControlStatus) {
        controlsView.playButton.setTimeControlStatus(status)
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateDuration duration: CMTime) {
        controlsView.timeSlider.duration = duration
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdatePresentationSize size: CGSize) {
        updateSubtitles()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateTracks tracks: [AVPlayerItemTrack]) {
        updateSubtitles()
    }
}

// MARK: - Private

private extension PlayerViewController {

    func configureViews() {
        playerView.delegate = self
        
        controlsView.previousButton.repeatAction = { [weak self] in
            self?.step(byCount: -1)
        }

        controlsView.nextButton.repeatAction = { [weak self] in
            self?.step(byCount: 1)
        }

        controlsView.playButton.setTimeControlStatus(.paused)
        updateViews(withTime: .zero)
        updateFrameSelection()
        updateControlsEnabled()
        updateReadyForInitialPlayback()
    }

    func updateReadyForInitialPlayback() {
        guard !isReadyForInitialPlayback,
            (playbackController?.isReadyToPlay ?? false),
            playerView.isReadyForDisplay else { return }

        isReadyForInitialPlayback = true
        delegate?.controllerIsReadyForInitialPlayback(self)
    }

    func updateControlsEnabled() {
        let isReady = playbackController?.isReadyToPlay ?? false
        let canAddFrame = thumbnailsViewController.selectedThumbnail == nil
        controlsView.setControlsEnabled(isReady)
        controlsView.addFrameButton.isEnabled = isReady && canAddFrame
    }

    func updateViews(withTime time: CMTime) {
        let showMilliseconds = playbackController?.isPlaying == false
        let formattedTime = timeFormatter.string(fromCurrentTime: time, includeMilliseconds: showMilliseconds)
        controlsView.timeLabel.text = formattedTime

        if !isScrubbing {
            controlsView.timeSlider.time = time
        }
    }

    func updateFrameSelection() {
        updateControlsEnabled()
        updateTitle()
        updateSubtitles()
        titleView.thumbnailsContainer.setHidden(selectedFrames.isEmpty, animated: false)
    }

    func updateTitle() {
        let format = NSLocalizedString("player.selectedFramesPlural", comment: "")
        titleView.titleLabel.text = String.localizedStringWithFormat(format, thumbnailsViewController.thumbnails.count)
    }

    func updateSubtitles() {
        guard selectedFrames.isEmpty,
            let size = playbackController?.video.pixelSize,
            let frameRate = playbackController?.video.frameRate
        else {
            titleView.subtitleContainer.setHidden(true, animated: false)
            return
        }

        titleView.dimensionsLabel.text = NumberFormatter().string(fromPixelWidth: Int(size.width), height: Int(size.height))
        titleView.frameRateLabel.text = NumberFormatter.frameRateFormatter().string(from: frameRate)
        titleView.subtitleContainer.setHidden(false, animated: true)
    }
}

// MARK: - Transition

extension PlayerViewController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        playerView.setHidden(true, animated: false)
        titleView.setHidden(true, animated: false)
        controlsView.setHidden(true, animated: false)
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        playerView.setHidden(false, animated: false)
        titleView.setHidden(false, animated: true)
        controlsView.setHidden(false, animated: true)
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        return nil
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        let frame = playerView.zoomedVideoFrame
        return (frame.size != .zero) ? view.convert(frame, to: view) : nil
    }
}
