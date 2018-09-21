import UIKit
import AVKit

protocol PlayerOverlaysControllerDelegate: class {
    func controllerDidSelectDone(_ controller: PlayerOverlaysController)
    func controller(_ controller: PlayerOverlaysController, didSelectShareFrames frames: [Any])
    func controllerGeneratingFrameDidFail(_ controller: PlayerOverlaysController)
}

/// Manages the title and player controls view, video playback and generating frames.
class PlayerOverlaysController: UIViewController {

    weak var delegate: PlayerOverlaysControllerDelegate?
    var settings = UserDefaults.standard
    var videoManager: VideoManager!

    var playbackController: PlaybackController? {
        didSet { playbackController?.observers.add(self) }
    }

    private var selectedFramesViewController: FrameThumbnailsViewController!
    private lazy var timeFormatter = VideoTimeFormatter()

    @IBOutlet private var titleView: PlayerTitleView!
    @IBOutlet private var controlsView: PlayerControlsView!

    private var isScrubbing: Bool {
        return controlsView.timeSlider.isInteracting
    }

    private var isSeeking: Bool {
        return playbackController?.isSeeking ?? false
    }

    private var hasSelection: Bool {
        return !selectedFramesViewController.frames.isEmpty
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let controller = segue.destination as? FrameThumbnailsViewController {
            selectedFramesViewController = controller
            selectedFramesViewController.delegate = self
        }
    }
}

// MARK: - Actions

private extension PlayerOverlaysController {

    @IBAction func done() {
        playbackController?.pause()
        delegate?.controllerDidSelectDone(self)
    }

    @IBAction func playOrPause() {
        guard !isScrubbing else { return }

        playbackController?.playOrPause()
        selectedFramesViewController.clearSelection()
    }

    func step(byCount count: Int) {
        guard !isScrubbing else { return }

        playbackController?.step(byCount: count)
        selectedFramesViewController.clearSelection()
    }

    @IBAction func scrub(_ sender: TimeSlider) {
        playbackController?.seeker.smoothlySeek(to: sender.time)
        // When scrubbing, display slider time instead of player time.
        updateViews(withTime: sender.time)
        selectedFramesViewController.clearSelection()
    }

    @IBAction func addCurrentFrame() {
        generateCurrentFrame {
            selectedFramesViewController.insertFrame($0)
        }
    }

    @IBAction func shareFrames() {
        playbackController?.pause()

        if hasSelection {
            shareFrames(selectedFramesViewController.frames)
        } else {
            generateCurrentFrame {
                shareFrames([$0])
            }
        }
    }

    func showFrame(_ frame: Frame) {
        guard !isScrubbing else { return }

        playbackController?.pause()
        playbackController?.seeker.smoothlySeek(to: frame.time)
    }
}

// MARK: Image Generation & Sharing

private extension PlayerOverlaysController {

    func generateCurrentFrame(successHandler: (Frame) -> ()) {
        guard let frame = playbackController?.currentItem.flatMap(videoManager.currentFrame) else {
            delegate?.controllerGeneratingFrameDidFail(self)
            return
        }

        successHandler(frame)
    }

    func shareFrames(_ frames: [Frame]) {
        if settings.includeMetadata {
            delegate?.controller(self, didSelectShareFrames: imagesByAddingMetadata(to: frames))
        } else {
            delegate?.controller(self, didSelectShareFrames: frames.map { $0.image })
        }
    }

    /// If metadata generation fails returns the plain image.
    func imagesByAddingMetadata(to frames: [Frame]) -> [Any] {
        return frames.map {
            videoManager.jpegData(byAddingAssetMetadataTo: $0.image, compressionQuality: 1) ?? ($0.image as Any)
        }
    }
}

// MARK: - FrameThumbnailsViewControllerDelegate

extension PlayerOverlaysController: FrameThumbnailsViewControllerDelegate {

    func controllerSelectionChanged(_ controller: FrameThumbnailsViewController) {
        if let frame = selectedFramesViewController.selectedFrame {
            showFrame(frame)
        }

        updateFrameSelection()
    }

    func controllerFramesChanged(_ controller: FrameThumbnailsViewController) {
        updateFrameSelection()
    }
}

// MARK: - PlayerObserver

extension PlayerOverlaysController: PlayerObserver {

    func player(_ player: AVPlayer, didUpdateStatus status: AVPlayer.Status) {
        updateControlsEnabled()
    }

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateStatus status: AVPlayerItem.Status) {
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

    func currentPlayerItem(_ playerItem: AVPlayerItem, didUpdateTracks tracks: [AVPlayerItemTrack]) {
        updateSubtitles()
    }
}

private extension PlayerOverlaysController {

    func configureViews() {
        view.backgroundColor = nil
        
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
    }

    func updateControlsEnabled() {
        let isReady = playbackController?.isReadyToPlay ?? false
        let canAddFrame = selectedFramesViewController.selectedFrame == nil
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
        selectedFramesViewController.setHidden(!hasSelection, animated: false)
    }

    func updateTitle() {
        let selectedFrames = selectedFramesViewController?.frames.count ?? 0
        let format = NSLocalizedString("player.selectedFramesPlural", comment: "")
        titleView.titleLabel.text = String.localizedStringWithFormat(format, selectedFrames)
    }

    func updateSubtitles() {
        guard
            !hasSelection,
            let dimensions = videoManager?.pixelSize,
            let frameRate = playbackController?.frameRate
        else {
            titleView.subtitleStack.setHidden(true, animated: false)
            return
        }

        titleView.dimensionsLabel.text = NumberFormatter().string(fromPixelWidth: Int(dimensions.width), height: Int(dimensions.height))
        titleView.frameRateLabel.text = NumberFormatter.frameRateFormatter().string(from: frameRate)
        titleView.subtitleStack.setHidden(false, animated: true)
    }
}
