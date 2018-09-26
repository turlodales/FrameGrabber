import UIKit
import AVKit
import Photos

class PlayerContainerController: UIViewController {

    var videoAsset: PHAsset!
    lazy var metadataOptionProvider: UserDefaults = .standard

    private(set) var loadingViewController: PlayerLoadingViewController!
    private(set) var playerViewController: PlayerViewController!

    private var backgroundView: BlurredImageView {
        return view as! BlurredImageView
    }

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

        case let controller as PlayerLoadingViewController:
            controller.videoAsset = videoAsset
            controller.delegate = self
            loadingViewController = controller

        case let controller as PlayerViewController:
            controller.delegate = self
            playerViewController = controller

        default: break
        }
    }

    func done() {
        dismiss(animated: true)
    }
}

// MARK: - PlayerLoadingViewControllerDelegate

extension PlayerContainerController: PlayerLoadingViewControllerDelegate {

    func controllerDidCancel(_ controller: PlayerLoadingViewController) {
        done()
    }

    func controller(_ controller: PlayerLoadingViewController, didFinishLoadingPreviewImage image: UIImage) {
        backgroundView.image = image
    }

    func controller(_ controller: PlayerLoadingViewController, didFinishLoadingVideo video: Video) {
        playerViewController.video = video
    }

    func controllerLoadingVideoDidFail(_ controller: PlayerLoadingViewController) {
        presentAlert(.videoLoadingFailed() { _ in self.done() })
    }
}

// MARK: - PlayerViewControllerDelegate

extension PlayerContainerController: PlayerViewControllerDelegate {

    func controllerDidSelectDone(_ controller: PlayerViewController) {
        done()
    }

    func controllerIsReadyForInitialPlayback(_ controller: PlayerViewController) {
        loadingViewController.setHidden(true, animated: false)
    }

    func controllerPlaybackDidFail(_ controller: PlayerViewController) {
        presentAlert(.playbackFailed())
    }

    func controllerGeneratingFramesDidFail(_ controller: PlayerViewController) {
        presentAlert(.imageGenerationFailed())
    }

    func controller(_ controller: PlayerViewController, didSelectShareFrames frames: [Frame]) {
        let includeMetadata = metadataOptionProvider.includeMetadata

        let images = frames.map {
            $0.image.jpegData(includingMetadata: includeMetadata) ?? ($0.image.image as Any)
        }

        let shareController = UIActivityViewController(activityItems: images, applicationActivities: nil)
        present(shareController, animated: true)
    }
}

// MARK: - Private

private extension PlayerContainerController {

    func configureViews() {
        view.backgroundColor = nil
        backgroundView.backgroundColor = nil
        playerViewController.view.backgroundColor = nil
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
        playerViewController.toggleOverlays(animated: true)
    }

    @objc func handleSwipeDown(sender: UIGestureRecognizer) {
        guard sender.state == .ended else { return }
        done()
    }
}
