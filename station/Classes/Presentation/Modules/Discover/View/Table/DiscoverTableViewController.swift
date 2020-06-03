import UIKit
import BTKit

enum DiscoverTableSection {
    case webTag
    case device
    case noDevices

    static var count = 2 // displayed simultaneously

    static func section(for index: Int, deviceCount: Int) -> DiscoverTableSection {
        if deviceCount > 0 {
            return index == 0 ? .webTag : .device
        } else {
            return index == 0 ? .webTag : .noDevices
        }
    }
}

class DiscoverTableViewController: UITableViewController {

    var output: DiscoverViewOutput!

    @IBOutlet var closeBarButtonItem: UIBarButtonItem!
    @IBOutlet var btDisabledEmptyDataSetView: UIView!
    @IBOutlet weak var btDisabledImageView: UIImageView!
    @IBOutlet var getMoreSensorsEmptyDataSetView: UIView!
    @IBOutlet weak var getMoreSensorsFooterButton: UIButton!
    @IBOutlet weak var getMoreSensorsEmptyDataSetButton: UIButton!

    var webTags: [DiscoverWebTagViewModel] = [DiscoverWebTagViewModel]()
    var savedWebTagProviders: [WeatherProvider] = [WeatherProvider]() {
        didSet {
            shownWebTags = webTags
                .filter({
                    if hideAlreadyAddedWebProviders {
                        return !savedWebTagProviders.contains($0.provider)
                    } else {
                        return true
                    }
                })
                .sorted(by: { $0.locationType.title < $1.locationType.title })
        }
    }

    var devices: [DiscoverDeviceViewModel] = [DiscoverDeviceViewModel]() {
        didSet {
            shownDevices = devices
                .filter({ !savedDevicesIds.contains($0.id) })
                .sorted(by: {
                    if let rssi0 = $0.rssi, let rssi1 = $1.rssi {
                        return rssi0 > rssi1
                    } else {
                        return false
                    }
                })
        }
    }
    var savedDevicesIds: [String] = [String]() {
        didSet {
            shownDevices = devices
                .filter({ !savedDevicesIds.contains($0.id) })
                .sorted(by: {
                    if let rssi0 = $0.rssi, let rssi1 = $1.rssi {
                        return rssi0 > rssi1
                    } else {
                        return false
                    }
                })
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
    private let deviceCellReuseIdentifier = "DiscoverDeviceTableViewCellReuseIdentifier"
    private let webTagCellReuseIdentifier = "DiscoverWebTagTableViewCellReuseIdentifier"
    private let noDevicesCellReuseIdentifier = "DiscoverNoDevicesTableViewCellReuseIdentifier"
    private let webTagsInfoSectionHeaderReuseIdentifier = "DiscoverWebTagsInfoHeaderFooterView"
    private var shownDevices: [DiscoverDeviceViewModel] =  [DiscoverDeviceViewModel]() {
        didSet {
            updateUIShownDevices()
        }
    }
    private var shownWebTags: [DiscoverWebTagViewModel] = [DiscoverWebTagViewModel]() {
        didSet {
            updateUIShownWebTags()
        }
    }
}

// MARK: - DiscoverViewInput
extension DiscoverTableViewController: DiscoverViewInput {
    func localize() {
        navigationItem.title = "DiscoverTable.NavigationItem.title".localized()
        getMoreSensorsFooterButton.setTitle("DiscoverTable.GetMoreSensors.button.title".localized(), for: .normal)
        getMoreSensorsEmptyDataSetButton.setTitle("DiscoverTable.GetMoreSensors.button.title".localized(), for: .normal)
    }

    func showBluetoothDisabled() {
        let title = "DiscoverTable.BluetoothDisabledAlert.title".localized()
        let message = "DiscoverTable.BluetoothDisabledAlert.message".localized()
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil))
        present(alertVC, animated: true)
    }

    func showWebTagInfoDialog() {
        let message = "DiscoverTable.WebTagsInfoDialog.message".localized()
        let alertVC = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "OK".localized(), style: .cancel, handler: nil))
        present(alertVC, animated: true)
    }
}

// MARK: - IBActions
extension DiscoverTableViewController {
    @IBAction func closeBarButtonItemAction(_ sender: Any) {
        output.viewDidTriggerClose()
    }

    @IBAction func getMoreSensorsTableFooterViewButtonTouchUpInside(_ sender: Any) {
        output.viewDidTapOnGetMoreSensors()
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
        let section = DiscoverTableSection.section(for: section, deviceCount: shownDevices.count)
        switch section {
        case .webTag:
            return shownWebTags.count
        case .device:
            return shownDevices.count
        case .noDevices:
            return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = DiscoverTableSection.section(for: indexPath.section, deviceCount: shownDevices.count)
        switch section {
        case .webTag:
            // swiftlint:disable force_cast
            let cell = tableView
                .dequeueReusableCell(withIdentifier: webTagCellReuseIdentifier,
                                     for: indexPath) as! DiscoverWebTagTableViewCell
            // swiftlint:enable force_cast
            let tag = shownWebTags[indexPath.row]
            configure(cell: cell, with: tag)
            return cell
        case .device:
            // swiftlint:disable force_cast
            let cell = tableView
                .dequeueReusableCell(withIdentifier: deviceCellReuseIdentifier,
                                     for: indexPath) as! DiscoverDeviceTableViewCell
            // swiftlint:enable force_cast
            let tag = shownDevices[indexPath.row]
            configure(cell: cell, with: tag)
            return cell
        case .noDevices:
            // swiftlint:disable force_cast
            let cell = tableView
                .dequeueReusableCell(withIdentifier: noDevicesCellReuseIdentifier,
                                     for: indexPath) as! DiscoverNoDevicesTableViewCell
            // swiftlint:enable force_cast
            cell.descriptionLabel.text = isBluetoothEnabled
                ? "DiscoverTable.NoDevicesSection.NotFound.text".localized()
                : "DiscoverTable.NoDevicesSection.BluetoothDisabled.text".localized()
            return cell
        }
    }
}

// MARK: - UITableViewDelegate {
extension DiscoverTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let section = DiscoverTableSection.section(for: indexPath.section, deviceCount: shownDevices.count)
        switch section {
        case .webTag:
            if indexPath.row < shownWebTags.count {
                output.viewDidChoose(webTag: shownWebTags[indexPath.row])
            }
        case .device:
            if indexPath.row < shownDevices.count {
                let device = shownDevices[indexPath.row]
                output.viewDidChoose(device: device, displayName: displayName(for: device))
            }
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let s = DiscoverTableSection.section(for: section, deviceCount: shownDevices.count)
        if s == .webTag {
            return 60
        } else {
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 40
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = DiscoverTableSection.section(for: section, deviceCount: shownDevices.count)
        if section == .webTag {
            // swiftlint:disable force_cast
            let header = tableView
                .dequeueReusableHeaderFooterView(withIdentifier: webTagsInfoSectionHeaderReuseIdentifier)
                as! DiscoverWebTagsInfoHeaderFooterView
            // swiftlint:enable force_cast
            header.delegate = self
            return header
        } else {
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = DiscoverTableSection.section(for: section, deviceCount: shownDevices.count)
        switch section {
        case .device:
            return shownDevices.count > 0 ? "DiscoverTable.SectionTitle.Devices".localized() : nil
        case .noDevices:
            return shownDevices.count == 0 ? "DiscoverTable.SectionTitle.Devices".localized() : nil
        default:
            return nil
        }

    }
}

// MARK: - DiscoverWebTagsInfoHeaderFooterViewDelegate
extension DiscoverTableViewController: DiscoverWebTagsInfoHeaderFooterViewDelegate {
    func discoverWebTagsInfo(headerView: DiscoverWebTagsInfoHeaderFooterView, didTapOnInfo button: UIButton) {
        output.viewDidTapOnWebTagInfo()
    }
}

// MARK: - Cell configuration
extension DiscoverTableViewController {
    private func configure(cell: DiscoverWebTagTableViewCell, with tag: DiscoverWebTagViewModel) {
        cell.nameLabel.text = tag.locationType.title
        cell.iconImageView.image = tag.icon
    }

    private func configure(cell: DiscoverDeviceTableViewCell, with device: DiscoverDeviceViewModel) {

        cell.identifierLabel.text = displayName(for: device)
        cell.isConnectableImageView.isHidden = !device.isConnectable

        // RSSI
        if let rssi = device.rssi {
            cell.rssiLabel.text = "\(rssi)" + " " + "dBm".localized()
            if rssi < -80 {
                cell.rssiImageView.image = UIImage(named: "icon-connection-1")
            } else if rssi < -50 {
                cell.rssiImageView.image = UIImage(named: "icon-connection-2")
            } else {
                cell.rssiImageView.image = UIImage(named: "icon-connection-3")
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
        let nib = UINib(nibName: "DiscoverWebTagsInfoHeaderFooterView", bundle: nil)
        tableView.register(nib, forHeaderFooterViewReuseIdentifier: webTagsInfoSectionHeaderReuseIdentifier)
    }

    private func configureBTDisabledImageView() {
        btDisabledImageView.tintColor = .red
    }
}

// MARK: - Update UI
extension DiscoverTableViewController {
    private func updateUI() {
        updateUIShownDevices()
        updateUIShownWebTags()
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

    private func updateUIShownDevices() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    private func updateUIShownWebTags() {
        if isViewLoaded {
            tableView.reloadData()
        }
    }

    private func displayName(for device: DiscoverDeviceViewModel) -> String {
        // identifier
        if let mac = device.mac {
            return "DiscoverTable.RuuviDevice.prefix".localized()
                + " " + mac.replacingOccurrences(of: ":", with: "").suffix(4)
        } else {
            return "DiscoverTable.RuuviDevice.prefix".localized()
                + " " + device.id.prefix(4)
        }
    }
}
