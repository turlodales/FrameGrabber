import UIKit

extension PlayerContainerController: ZoomAnimatable {

    func zoomAnimatorAnimationWillBegin(_ animator: ZoomAnimator) {
        loadingViewController.zoomAnimatorAnimationWillBegin(animator)
        playerViewController.zoomAnimatorAnimationWillBegin(animator)
    }

    func zoomAnimatorAnimationDidEnd(_ animator: ZoomAnimator) {
        loadingViewController.zoomAnimatorAnimationDidEnd(animator)
        playerViewController.zoomAnimatorAnimationDidEnd(animator)
    }

    func zoomAnimatorImage(_ animator: ZoomAnimator) -> UIImage? {
        return playerViewController.zoomAnimatorImage(animator)
            ?? loadingViewController.zoomAnimatorImage(animator)
    }

    func zoomAnimator(_ animator: ZoomAnimator, imageFrameInView view: UIView) -> CGRect? {
        return playerViewController.zoomAnimator(animator, imageFrameInView: view)
            ?? loadingViewController.zoomAnimator(animator, imageFrameInView: view)
    }
}
