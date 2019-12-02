import UIKit

class ActivityRuuviLogoViewController: UIViewController {
    var statusBarStyle = UIStatusBarStyle.default
    var statusBarHidden = false

    @IBOutlet weak var spinnerView: ActivitySpinnerView!
    @IBOutlet weak var logoImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        logoImageView.tintColor = UIColor.white
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        guard let topVC = UIApplication.shared.topViewController() else { return statusBarStyle }
        if !topVC.isKind(of: ActivityRuuviLogoViewController.self) {
            statusBarStyle = topVC.preferredStatusBarStyle
        }
        return statusBarStyle
    }

    override var prefersStatusBarHidden: Bool {
        guard let topVC = UIApplication.shared.topViewController() else { return statusBarHidden }
        if !topVC.isKind(of: ActivityRuuviLogoViewController.self) {
            statusBarHidden = topVC.prefersStatusBarHidden
        }
        return statusBarHidden
    }
}
