import UIKit
import BTKit
import RuuviOntology
import RuuviVirtual
import RuuviLocalization
import RuuviBundleUtils

enum DiscoverTableSection {
    case device
    case noDevices

    static var count = 1 // displayed simultaneously

    static func section(for deviceCount: Int) -> DiscoverTableSection {
        return deviceCount > 0 ? .device : .noDevices
    }
}

class DiscoverTableViewController: UITableViewController {

    var output: DiscoverViewOutput!

    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet var btDisabledEmptyDataSetView: UIView!
    @IBOutlet weak var btDisabledImageView: UIImageView!
    @IBOutlet var getMoreSensorsEmptyDataSetView: UIView!
    @IBOutlet weak var getMoreSensorsEmptyDataSetButton: UIButton!

    private var alertVC: UIAlertController?

    var ruuviTags: [DiscoverRuuviTagViewModel] = [DiscoverRuuviTagViewModel]() {
        didSet {
            updateTableView()
        }
    }

    var isBluetoothEnabled: Bool = true {
        didSet {
            updateUIISBluetoothEnabled()
        }
    }

    var isCloseEnabled: Bool = true {
        didSet {
            updateUIIsCloseEnabled()
        }
    }

    private let hideAlreadyAddedWebProviders = false
    private var emptyDataSetView: UIView?
}

// MARK: - DiscoverViewInput
extension DiscoverTableViewController: DiscoverViewInput {

    func localize() {
        navigationItem.title = "DiscoverTable.NavigationItem.title".localized(for: Self.self)
        getMoreSensorsEmptyDataSetButton.setTitle(
            "DiscoverTable.GetMoreSensors.button.title".localized(for: Self.self),
            for: .normal
        )
    }

    func showBluetoothDisabled() {
        let title = "DiscoverTable.BluetoothDisabledAlert.title".localized(for: Self.self)
        let message = "DiscoverTable.BluetoothDisabledAlert.message".localized(for: Self.self)
        showAlert(title: title, message: message)
    }

    func showWebTagInfoDialog() {
        let message = "DiscoverTable.WebTagsInfoDialog.message".localized(for: Self.self)
        let alertVC = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK".localized(for: Self.self), style: .cancel, handler: nil))
        present(alertVC, animated: true)
    }
}

// MARK: - IBActions
extension DiscoverTableViewController {
    @IBAction func closeBarButtonItemAction(_ sender: Any) {
        output.viewDidTriggerClose()
    }
}

// MARK: - View lifecycle
extension DiscoverTableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
        configureViews()
        updateUI()
        output.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        navigationItem.setHidesBackButton(true, animated: animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        output.viewWillAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        output.viewWillDisappear()
    }
}

// MARK: - UITableViewDataSource
extension DiscoverTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return DiscoverTableSection.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let section = DiscoverTableSection.section(for: ruuviTags.count)
        switch section {
        case .device:
            return ruuviTags.count
        case .noDevices:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = DiscoverTableSection.section(for: ruuviTags.count)
        switch section {
        case .device:
            let cell = tableView.dequeueReusableCell(with: DiscoverDeviceTableViewCell.self, for: indexPath)
            let tag = ruuviTags[indexPath.row]
            configure(cell: cell, with: tag)
            return cell
        case .noDevices:
            let cell = tableView.dequeueReusableCell(with: DiscoverNoDevicesTableViewCell.self, for: indexPath)
            cell.descriptionLabel.text = isBluetoothEnabled
                ? "DiscoverTable.NoDevicesSection.NotFound.text".localized(for: Self.self)
                : "DiscoverTable.NoDevicesSection.BluetoothDisabled.text".localized(for: Self.self)
            return cell
        }
    }
}

// MARK: - UITableViewDelegate {
extension DiscoverTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let sectionType = DiscoverTableSection.section(for: ruuviTags.count)
        switch sectionType {
        case .device:
            if indexPath.row < ruuviTags.count {
                let device = ruuviTags[indexPath.row]
                output.viewDidChoose(device: device, displayName: displayName(for: device))
            }
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 40
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let sectionType = DiscoverTableSection.section(for: ruuviTags.count)
        switch sectionType {
        case .device:
            return ruuviTags.count > 0 ? "DiscoverTable.SectionTitle.Devices".localized(for: Self.self) : nil
        case .noDevices:
            return ruuviTags.count == 0 ? "DiscoverTable.SectionTitle.Devices".localized(for: Self.self) : nil
        default:
            return nil
        }
    }
}

// MARK: - Cell configuration
extension DiscoverTableViewController {

    private func configure(cell: DiscoverDeviceTableViewCell, with device: DiscoverRuuviTagViewModel) {

        cell.identifierLabel.text = displayName(for: device)

        // RSSI
        if let rssi = device.rssi {
            cell.rssiLabel.text = "\(rssi)" + " " + "dBm".localized(for: Self.self)
            if rssi < -80 {
                cell.rssiImageView.image = UIImage.named("icon-connection-1", for: Self.self)
            } else if rssi < -50 {
                cell.rssiImageView.image = UIImage.named("icon-connection-2", for: Self.self)
            } else {
                cell.rssiImageView.image = UIImage.named("icon-connection-3", for: Self.self)
            }
        } else {
            cell.rssiImageView.image = nil
            cell.rssiLabel.text = nil
        }
    }
}

// MARK: - View configuration
extension DiscoverTableViewController {
    private func configureViews() {
        configureTableView()
        configureBTDisabledImageView()
    }

    private func configureTableView() {
        tableView.rowHeight = 44
    }

    private func configureBTDisabledImageView() {
        btDisabledImageView.tintColor = .red
    }
}

// MARK: - Update UI
extension DiscoverTableViewController {
    private func updateUI() {
        updateTableView()
        updateUIISBluetoothEnabled()
        updateUIIsCloseEnabled()
    }

    private func updateUIIsCloseEnabled() {
        if isViewLoaded {
            if isCloseEnabled {
                navigationItem.leftBarButtonItem = closeBarButtonItem
            } else {
                navigationItem.leftBarButtonItem = nil
            }
        }
    }

    private func updateUIISBluetoothEnabled() {
        if isViewLoaded {
            emptyDataSetView = isBluetoothEnabled ? getMoreSensorsEmptyDataSetView : btDisabledEmptyDataSetView
        }
    }

    private func updateTableView() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    private func displayName(for device: DiscoverRuuviTagViewModel) -> String {
        // identifier
        if let mac = device.mac {
            return "DiscoverTable.RuuviDevice.prefix".localized(for: Self.self)
                + " " + mac.replacingOccurrences(of: ":", with: "").suffix(4)
        } else {
            return "DiscoverTable.RuuviDevice.prefix".localized(for: Self.self)
                + " " + (device.luid?.value.prefix(4) ?? "")
        }
    }
}
// swiftlint:enable file_length
