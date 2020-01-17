import UIKit

class AboutViewController: UIViewController {
    var output: AboutViewOutput!

    @IBOutlet weak var aboutTextView: UITextView!
    @IBOutlet weak var versionLabel: UILabel!

    private let twoNewlines = "\n\n"
    private let fourNewlines = "\n\n\n\n"

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.lightContent
    }
}

// MARK: - AboutViewInput
extension AboutViewController: AboutViewInput {
    func localize() {
        configureTextView()
        configureVersionLabel()
    }
}

// MARK: - IBActions
extension AboutViewController {

    @IBAction func backButtonTouchUpInside(_ sender: Any) {
        output.viewDidTriggerClose()
    }

}

// MARK: - View lifecycle
extension AboutViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
        configureViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.main.async {
            UIView.setAnimationsEnabled(false)
            self.aboutTextView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.setAnimationsEnabled(true)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        aboutTextView.layoutManager.allowsNonContiguousLayout = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: { (_) in
            UIView.setAnimationsEnabled(false)
            self.aboutTextView.scrollRangeToVisible(NSRange(location: 0, length: 0))
            UIView.setAnimationsEnabled(true)
        })
    }
}

// MARK: - UITextViewDelegate
extension AboutViewController: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL, options: [:])
        return false
    }
}

// MARK: - View configuration
extension AboutViewController {
    private func configureViews() {
        configureTextView()
        configureVersionLabel()
    }

    private func configureVersionLabel() {
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
            let buildVersion = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            versionLabel.text = "About.Version.text".localized() + " " + appVersion + "(" + buildVersion + ")"
        } else {
            versionLabel.text = nil
        }
    }

    private func configureTextView() {

        let text = "About.AboutHelp.header".localized() + twoNewlines +
            "About.AboutHelp.contents".localized() + fourNewlines +
            "About.OperationsManual.header".localized() + twoNewlines +
            "About.OperationsManual.contents".localized() + fourNewlines +
            "About.Troubleshooting.header".localized() + twoNewlines +
            "About.Troubleshooting.contents".localized() + fourNewlines +
            "About.OpenSource.header".localized() + twoNewlines +
            "About.OpenSource.contents".localized() + fourNewlines +
            "About.More.header".localized() + twoNewlines +
            "About.More.contents".localized() + "\n"

        let attrString = NSMutableAttributedString(string: text)
        let muliRegular = UIFont(name: "Muli-Regular", size: 16.0) ?? UIFont.systemFont(ofSize: 16)
        let range = NSString(string: attrString.string).range(of: attrString.string)
        attrString.addAttribute(NSAttributedString.Key.font, value: muliRegular, range: range)

        // make headers bold
        let makeBold = ["About.AboutHelp.header".localized(),
                        "About.OperationsManual.header".localized(),
                        "About.Troubleshooting.header".localized(),
                        "About.OpenSource.header".localized(),
                        "About.More.header".localized()]
        let boldFont = UIFont(name: "Montserrat-Bold", size: 16) ?? UIFont.systemFont(ofSize: 16, weight: .bold)
        for bold in makeBold {
            let range = NSString(string: attrString.string).range(of: bold)
            attrString.addAttribute(NSAttributedString.Key.font, value: boldFont, range: range)
        }
        // reduce the linespacing below the titles
        let smallFont = UIFont(name: "Muli-Bold", size: 8) ?? UIFont.systemFont(ofSize: 8)
        for range in attrString.string.ranges(of: "\n") {
            attrString.addAttribute(NSAttributedString.Key.font,
                                    value: smallFont,
                                    range: NSRange(range, in: attrString.string))
        }

        // make text color white
        attrString.addAttribute(.foregroundColor,
                                value: UIColor.white,
                                range: NSRange(location: 0, length: attrString.length))

        aboutTextView.attributedText = attrString
    }
}

private extension String {
    func ranges(of substring: String, options: CompareOptions = [], locale: Locale? = nil) -> [Range<Index>] {
        var ranges: [Range<Index>] = []
        while ranges.last.map({ $0.upperBound < self.endIndex }) ?? true,
            let range = self.range(of: substring,
                                   options: options,
                                   range: (ranges.last?.upperBound ?? self.startIndex)..<self.endIndex,
                                   locale: locale) {
            ranges.append(range)
        }
        return ranges
    }
}
