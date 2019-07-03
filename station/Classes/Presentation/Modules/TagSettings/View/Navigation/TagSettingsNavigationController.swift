import UIKit

class TagSettingsNavigationController: UINavigationController, UIGestureRecognizerDelegate {
    lazy var panGR: UIPanGestureRecognizer = {
        let panGR = UIPanGestureRecognizer(target: self, action: #selector(TagSettingsNavigationController.handlePanGesture(_:)))
        panGR.delegate = self
        panGR.isEnabled = true
        return panGR
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addGestureRecognizer(panGR)
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        if let transition = transitioningDelegate as? TagSettingsTransitioningDelegate {
            let interactor = transition.interactionControllerForDismissal
            let percentThreshold:CGFloat = 0.3
            
            // convert y-position to downward pull progress (percentage)
            let translation = sender.translation(in: view)
            let verticalMovement = translation.y / view.bounds.height
            let downwardMovement = fmaxf(Float(verticalMovement), 0.0)
            let downwardMovementPercent = fminf(downwardMovement, 1.0)
            let progress = CGFloat(downwardMovementPercent)
            
            switch sender.state {
            case .began:
                if let tagSettings = topViewController as? TagSettingsTableViewController,
                    tagSettings.tableView.contentOffset.y <= 0 {
                    interactor.hasStarted = true
                    dismiss(animated: true)
                }
            case .changed:
                interactor.shouldFinish = progress > percentThreshold
                interactor.update(progress)
            case .cancelled:
                interactor.hasStarted = false
                interactor.cancel()
            case .ended:
                interactor.hasStarted = false
                interactor.shouldFinish
                    ? interactor.finish()
                    : interactor.cancel()
            default:
                break
            }
        }
    }
}
