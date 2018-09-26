import UIKit
import AVKit

/// Coordinates chrome, presentation and child controllers.
class PlayerContainerController: UIViewController {

    var videoManager: VideoManager!
    lazy var metadataOptionProvider: UserDefaults = .standard

    private(set) var playerViewController: PlayerViewController!
    private(set) var overlayViewController: PlayerOverlaysController!

    // MARK: Status Bar

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    override var prefersStatusBarHidden: Bool {
        let verticallyCompact = traitCollection.verticalSizeClass == .compact
        return verticallyCompact || shouldHideStatusBar
    }

    private var shouldHideStatusBar = false {
        didSet { setNeedsStatusBarAppearanceUpdate() }
    }

    private func hideStatusBar() {
        // For seamless transition from status bar to non status bar view controller, need to
        // a) keep `prefersStatusBarHidden` false until `viewWillAppear`, b) animate change
        // and c) use the transition coordinator to handle correct layout for GPS/phone bar.
        if let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: { _ in
                self.shouldHideStatusBar = true
            }, completion: nil)
        } else {
            UIView.animate(withDuration: 0.15) {
                self.shouldHideStatusBar = true
            }
        }
    }

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        hideStatusBar()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.destination {

        case let controller as PlayerViewController:
            controller.videoManager = videoManager
            controller.delegate = self
            playerViewController = controller

        case let controller as PlayerOverlaysController:
            controller.delegate = self
            overlayViewController = controller

        default: break
        }
    }

    func done() {
        dismiss(animated: true)
    }
}

// MARK: - PlayerViewControllerDelegate

extension PlayerContainerController: PlayerViewControllerDelegate {

    func controller(_ controller: PlayerViewController, loadingVideoDidFinish video: Video, playbackController: PlaybackController) {
        overlayViewController.playbackController = playbackController
    }

    func controllerLoadingVideoDidFail(_ controller: PlayerViewController) {
        presentAlert(.videoLoadingFailed() { _ in self.done() })
    }

    func controllerPlaybackDidFail(_ controller: PlayerViewController) {
        presentAlert(.playbackFailed { _ in self.done() })
    }
}

// MARK: - PlayerOverlaysControllerDelegate

extension PlayerContainerController: PlayerOverlaysControllerDelegate {

    func controllerDidSelectDone(_ controller: PlayerOverlaysController) {
        done()
    }

    func controllerGeneratingFrameDidFail(_ controller: PlayerOverlaysController) {
        presentAlert(.imageGenerationFailed())
    }

    func controller(_ controller: PlayerOverlaysController, didSelectShareFrames frames: [Frame]) {
        let includeMetadata = metadataOptionProvider.includeMetadata

        let images = frames
            .map { $0.image }
            .map { $0.jpegData(includingMetadata: includeMetadata) ?? ($0.image as Any) }

        let shareController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        present(shareController, animated: true)
    }
}

// MARK: - Private

private extension PlayerContainerController {

    func configureViews() {
        configureGestures()
    }

    func configureGestures() {
        guard let playerView = playerViewController.playerView else { return }

        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeDown))
        swipeRecognizer.direction = .down
        playerView.addGestureRecognizer(swipeRecognizer)

        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        tapRecognizer.require(toFail: playerView.doubleTapToZoomRecognizer)
        tapRecognizer.require(toFail: swipeRecognizer)
        playerView.addGestureRecognizer(tapRecognizer)
    }

    @objc func handleTap(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        overlayViewController.toggleHidden(animated: true)
    }

    @objc func handleSwipeDown(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        done()
    }
}
