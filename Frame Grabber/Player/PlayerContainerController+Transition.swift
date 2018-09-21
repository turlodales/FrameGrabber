import UIKit

extension PlayerContainerController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        playerViewController.zoomAnimatorAnimationWillBegin(animator)
        overlayViewController.setHidden(true, animated: false)
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        playerViewController.zoomAnimatorAnimationDidEnd(animator)
        overlayViewController.setHidden(false, animated: true)
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        return playerViewController.zoomAnimatorImage(animator)
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        return playerViewController.zoomAnimator(animator, imageFrameInView: view)
    }
}
