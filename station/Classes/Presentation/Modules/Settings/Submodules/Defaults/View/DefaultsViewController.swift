import UIKit
#if canImport(SwiftUI) && canImport(Combine)
import SwiftUI
#endif

class DefaultsViewController: UIViewController {
    var output: DefaultsViewOutput!

    var viewModels = [DefaultsViewModel]() {
        didSet {
#if canImport(SwiftUI) && canImport(Combine)
            if #available(iOS 13, *) {
                env.viewModels = viewModels
            }
#endif
            table?.viewModels = viewModels
        }
    }

    @IBOutlet weak var tableContainer: UIView!
    @IBOutlet weak var listContainer: UIView!

#if canImport(SwiftUI) && canImport(Combine)
    @available(iOS 13, *)
    private lazy var env = DefaultsEnvironmentObject()
#endif

    private var table: DefaultsTableViewController?
}

extension DefaultsViewController: DefaultsViewInput {
    func localize() {
        navigationItem.title = "Defaults.navigationItem.title".localized()
    }
}

// MARK: - View lifecycle
extension DefaultsViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
        configureViews()
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        #if SWIFTUI
        if #available(iOS 13, *) {
            return identifier == DefaultsEmbedSegue.list.rawValue
        } else {
            return identifier == DefaultsEmbedSegue.table.rawValue
        }
        #else
        return identifier == DefaultsEmbedSegue.table.rawValue
        #endif
    }

    #if SWIFTUI && canImport(SwiftUI) && canImport(Combine)
    @IBSegueAction func addSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        if #available(iOS 13, *) {
            env.viewModels = viewModels
            return UIHostingController(coder: coder, rootView: DefaultsList().environmentObject(env))
        } else {
            return nil
        }
    }
    #else
    @IBSegueAction func addSwiftUIView(_ coder: NSCoder) -> UIViewController? {
        return nil
    }
    #endif

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case DefaultsEmbedSegue.table.rawValue:
            table = segue.destination as? DefaultsTableViewController
            table?.output = output
            table?.viewModels = viewModels
        default:
            break
        }
    }
}

// MARK: - Configure Views
extension DefaultsViewController {
    func configureViews() {
        tableContainer.isHidden = !shouldPerformSegue(withIdentifier: DefaultsEmbedSegue.table.rawValue, sender: nil)
        listContainer.isHidden = !shouldPerformSegue(withIdentifier: DefaultsEmbedSegue.list.rawValue, sender: nil)
    }
}
