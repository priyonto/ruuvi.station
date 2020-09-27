// swiftlint:disable file_length
import UIKit
import RangeSeekSlider

enum TagSettingsTableSection: Int {
    case image = 0
    case name = 1
    case connection = 2
    case alerts = 3
    case calibration = 4
    case moreInfo = 5

    static func showConnection(for viewModel: TagSettingsViewModel?) -> Bool {
        return viewModel?.isConnectable.value ?? false
    }

    static func showAlerts(for viewModel: TagSettingsViewModel?) -> Bool {
        return viewModel?.isConnectable.value ?? false
    }

    static func section(for sectionIndex: Int) -> TagSettingsTableSection {
        return TagSettingsTableSection(rawValue: sectionIndex) ?? .name
    }
}

class TagSettingsTableViewController: UITableViewController {
    var output: TagSettingsViewOutput!

    @IBOutlet weak var movementAlertDescriptionCell: TagSettingsAlertDescriptionCell!
    @IBOutlet weak var movementAlertHeaderCell: TagSettingsAlertHeaderCell!

    @IBOutlet weak var connectionAlertDescriptionCell: TagSettingsAlertDescriptionCell!
    @IBOutlet weak var connectionAlertHeaderCell: TagSettingsAlertHeaderCell!

    @IBOutlet weak var pressureAlertHeaderCell: TagSettingsAlertHeaderCell!
    @IBOutlet weak var pressureAlertControlsCell: TagSettingsAlertControlsCell!

    @IBOutlet weak var dewPointAlertHeaderCell: TagSettingsAlertHeaderCell!
    @IBOutlet weak var dewPointAlertControlsCell: TagSettingsAlertControlsCell!

    @IBOutlet weak var temperatureAlertHeaderCell: TagSettingsAlertHeaderCell!
    @IBOutlet weak var temperatureAlertControlsCell: TagSettingsAlertControlsCell!

    @IBOutlet weak var humidityAlertHeaderCell: TagSettingsAlertHeaderCell!
    @IBOutlet weak var humidityAlertControlsCell: TagSettingsAlertControlsCell!

    @IBOutlet weak var connectStatusLabel: UILabel!
    @IBOutlet weak var keepConnectionSwitch: UISwitch!
    @IBOutlet weak var keepConnectionTitleLabel: UILabel!
    @IBOutlet weak var dataSourceTitleLabel: UILabel!
    @IBOutlet weak var dataSourceValueLabel: UILabel!
    @IBOutlet weak var humidityLabelTrailing: NSLayoutConstraint!
    @IBOutlet weak var macValueLabelTrailing: NSLayoutConstraint!
    @IBOutlet weak var txPowerValueLabelTrailing: NSLayoutConstraint!
    @IBOutlet weak var mcValueLabelTrailing: NSLayoutConstraint!
    @IBOutlet weak var msnValueLabelTrailing: NSLayoutConstraint!
    @IBOutlet weak var msnCell: UITableViewCell!
    @IBOutlet weak var mcCell: UITableViewCell!
    @IBOutlet weak var txPowerCell: UITableViewCell!
    @IBOutlet weak var uuidCell: UITableViewCell!
    @IBOutlet weak var macAddressCell: UITableViewCell!
    @IBOutlet weak var tagNameCell: UITableViewCell!
    @IBOutlet weak var calibrationHumidityCell: UITableViewCell!
    @IBOutlet weak var uuidValueLabel: UILabel!
    @IBOutlet weak var accelerationXValueLabel: UILabel!
    @IBOutlet weak var accelerationYValueLabel: UILabel!
    @IBOutlet weak var accelerationZValueLabel: UILabel!
    @IBOutlet weak var voltageValueLabel: UILabel!
    @IBOutlet weak var macAddressValueLabel: UILabel!
    @IBOutlet weak var humidityLabel: UILabel!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var tagNameTextField: UITextField!
    @IBOutlet weak var dataFormatValueLabel: UILabel!
    @IBOutlet weak var mcValueLabel: UILabel!
    @IBOutlet weak var msnValueLabel: UILabel!
    @IBOutlet weak var txPowerValueLabel: UILabel!
    @IBOutlet weak var backgroundImageLabel: UILabel!
    @IBOutlet weak var tagNameTitleLabel: UILabel!
    @IBOutlet weak var humidityTitleLabel: UILabel!
    @IBOutlet weak var uuidTitleLabel: UILabel!
    @IBOutlet weak var macAddressTitleLabel: UILabel!
    @IBOutlet weak var dataFormatTitleLabel: UILabel!
    @IBOutlet weak var batteryVoltageTitleLabel: UILabel!
    @IBOutlet weak var accelerationXTitleLabel: UILabel!
    @IBOutlet weak var accelerationYTitleLabel: UILabel!
    @IBOutlet weak var accelerationZTitleLabel: UILabel!
    @IBOutlet weak var txPowerTitleLabel: UILabel!
    @IBOutlet weak var mcTitleLabel: UILabel!
    @IBOutlet weak var msnTitleLabel: UILabel!
    @IBOutlet weak var removeThisRuuviTagButton: UIButton!

    var viewModel: TagSettingsViewModel? {
        didSet {
            bindViewModel()
        }
    }

    var measurementService: MeasurementsService!

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return UIStatusBarStyle.default
    }

    private let moreInfoSectionHeaderReuseIdentifier = "TagSettingsMoreInfoHeaderFooterView"
    private let alertsSectionHeaderReuseIdentifier = "TagSettingsAlertsHeaderFooterView"
    private let alertOffString = "TagSettings.Alerts.Off"
    private static var localizedCache: LocalizedCache = LocalizedCache()
}

// MARK: - TagSettingsViewInput
extension TagSettingsTableViewController: TagSettingsViewInput {

    func localize() {
        navigationItem.title = "TagSettings.navigationItem.title".localized()
        backgroundImageLabel.text = "TagSettings.backgroundImageLabel.text".localized()
        tagNameTitleLabel.text = "TagSettings.tagNameTitleLabel.text".localized()
        humidityTitleLabel.text = "TagSettings.humidityTitleLabel.text".localized()
        uuidTitleLabel.text = "TagSettings.uuidTitleLabel.text".localized()
        macAddressTitleLabel.text = "TagSettings.macAddressTitleLabel.text".localized()
        dataFormatTitleLabel.text = "TagSettings.dataFormatTitleLabel.text".localized()
        batteryVoltageTitleLabel.text = "TagSettings.batteryVoltageTitleLabel.text".localized()
        accelerationXTitleLabel.text = "TagSettings.accelerationXTitleLabel.text".localized()
        accelerationYTitleLabel.text = "TagSettings.accelerationYTitleLabel.text".localized()
        accelerationZTitleLabel.text = "TagSettings.accelerationZTitleLabel.text".localized()
        txPowerTitleLabel.text = "TagSettings.txPowerTitleLabel.text".localized()
        mcTitleLabel.text = "TagSettings.mcTitleLabel.text".localized()
        msnTitleLabel.text = "TagSettings.msnTitleLabel.text".localized()
        dataSourceTitleLabel.text = "TagSettings.dataSourceTitleLabel.text".localized()
        removeThisRuuviTagButton.setTitle("TagSettings.removeThisRuuviTagButton.text".localized(), for: .normal)

        updateUITemperatureAlertDescription()
        keepConnectionTitleLabel.text = "TagSettings.KeepConnection.title".localized()
        humidityAlertHeaderCell.titleLabel.text
            = "TagSettings.AirHumidityAlert.title".localized()
        pressureAlertHeaderCell.titleLabel.text
            = "TagSettings.PressureAlert.title".localized()
        connectionAlertHeaderCell.titleLabel.text = "TagSettings.ConnectionAlert.title".localized()
        movementAlertHeaderCell.titleLabel.text = "TagSettings.MovementAlert.title".localized()

        let alertPlaceholder = "TagSettings.Alert.CustomDescription.placeholder".localized()
        temperatureAlertControlsCell.textField.placeholder = alertPlaceholder
        humidityAlertControlsCell.textField.placeholder = alertPlaceholder
        dewPointAlertControlsCell.textField.placeholder = alertPlaceholder
        pressureAlertControlsCell.textField.placeholder = alertPlaceholder
        connectionAlertDescriptionCell.textField.placeholder = alertPlaceholder
        movementAlertDescriptionCell.textField.placeholder = alertPlaceholder

        tableView.reloadData()
    }

    func showTagRemovalConfirmationDialog() {
        let title = "TagSettings.confirmTagRemovalDialog.title".localized()
        let message = "TagSettings.confirmTagRemovalDialog.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Confirm".localized(),
                                           style: .destructive,
                                           handler: { [weak self] _ in
                                            self?.output.viewDidConfirmTagRemoval()
                                           }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showMacAddressDetail() {
        let title = "TagSettings.Mac.Alert.title".localized()
        let controller = UIAlertController(title: title, message: viewModel?.mac.value, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Copy".localized(), style: .default, handler: { [weak self] _ in
            if let mac = self?.viewModel?.mac.value {
                UIPasteboard.general.string = mac
            }
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showUUIDDetail() {
        let title = "TagSettings.UUID.Alert.title".localized()
        let controller = UIAlertController(title: title, message: viewModel?.uuid.value, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Copy".localized(), style: .default, handler: { [weak self] _ in
            if let uuid = self?.viewModel?.uuid.value {
                UIPasteboard.general.string = uuid
            }
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showUpdateFirmwareDialog() {
        let title = "TagSettings.UpdateFirmware.Alert.title".localized()
        let message = "TagSettings.UpdateFirmware.Alert.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionTitle = "TagSettings.UpdateFirmware.Alert.Buttons.LearnMore.title".localized()
        controller.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { [weak self] _ in
            self?.output.viewDidAskToLearnMoreAboutFirmwareUpdate()
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showHumidityIsClippedDialog() {
        let title = "TagSettings.HumidityIsClipped.Alert.title".localized()
        let message = "TagSettings.HumidityIsClipped.Alert.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionTitle = "TagSettings.HumidityIsClipped.Alert.Fix.button".localized()
        controller.addAction(UIAlertAction(title: actionTitle, style: .destructive, handler: { [weak self] _ in
            self?.output.viewDidAskToFixHumidityAdjustment()
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showBothNotConnectedAndNoPNPermissionDialog() {
        let message = "TagSettings.AlertsAreDisabled.Dialog.BothNotConnectedAndNoPNPermission.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionTitle = "TagSettings.AlertsAreDisabled.Dialog.Connect.title".localized()
        controller.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { [weak self] _ in
            self?.output.viewDidAskToConnectFromAlertsDisabledDialog()
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showNotConnectedDialog() {
        let message = "TagSettings.AlertsAreDisabled.Dialog.NotConnected.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let actionTitle = "TagSettings.AlertsAreDisabled.Dialog.Connect.title".localized()
        controller.addAction(UIAlertAction(title: actionTitle, style: .default, handler: { [weak self] _ in
            self?.output.viewDidAskToConnectFromAlertsDisabledDialog()
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }
}

// MARK: - View lifecycle
extension TagSettingsTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        setupLocalization()
        configureViews()
        bindViewModels()
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
}

// MARK: - IBActions
extension TagSettingsTableViewController {
    @IBAction func dismissBarButtonItemAction(_ sender: Any) {
        output.viewDidAskToDismiss()
    }

    @IBAction func removeThisRuuviTagButtonTouchUpInside(_ sender: Any) {
        output.viewDidAskToRemoveRuuviTag()
    }

    @IBAction func randomizeBackgroundButtonTouchUpInside(_ sender: Any) {
        output.viewDidAskToRandomizeBackground()
    }

    @IBAction func selectBackgroundButtonTouchUpInside(_ sender: UIButton) {
        output.viewDidAskToSelectBackground(sourceView: sender)
    }

    @IBAction func tagNameTextFieldEditingDidEnd(_ sender: Any) {
        if let name = tagNameTextField.text {
            output.viewDidChangeTag(name: name)
        }
    }

    @IBAction func keepConnectionSwitchValueChanged(_ sender: Any) {
        viewModel?.keepConnection.value = keepConnectionSwitch.isOn
        if !keepConnectionSwitch.isOn {
            viewModel?.isTemperatureAlertOn.value = false
            viewModel?.isHumidityAlertOn.value = false
            viewModel?.isDewPointAlertOn.value = false
            viewModel?.isPressureAlertOn.value = false
            viewModel?.isMovementAlertOn.value = false
        }
    }
}

// MARK: - UITableViewDelegate
extension TagSettingsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        switch cell {
        case tagNameCell:
            tagNameTextField.becomeFirstResponder()
        case calibrationHumidityCell:
            output.viewDidAskToCalibrateHumidity()
        case macAddressCell:
            output.viewDidTapOnMacAddress()
        case uuidCell:
            output.viewDidTapOnUUID()
        case txPowerCell:
            output.viewDidTapOnTxPower()
        case mcCell:
            output.viewDidTapOnMovementCounter()
        case msnCell:
            output.viewDidTapOnMeasurementSequenceNumber()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let section = TagSettingsTableSection.section(for: section)
        switch section {
        case .name:
            return "TagSettings.SectionHeader.Name.title".localized()
        case .calibration:
            return "TagSettings.SectionHeader.Calibration.title".localized()
        case .connection:
            return TagSettingsTableSection.showConnection(for: viewModel)
                ? "TagSettings.SectionHeader.Connection.title".localized() : nil
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else {
            return
        }
        switch cell {
        case calibrationHumidityCell:
            output.viewDidTapOnHumidityAccessoryButton()
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let section = TagSettingsTableSection.section(for: section)
        switch section {
        case .moreInfo:
            // swiftlint:disable force_cast
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: moreInfoSectionHeaderReuseIdentifier)
                as! TagSettingsMoreInfoHeaderFooterView
            // swiftlint:enable force_cast
            header.delegate = self
            header.noValuesView.isHidden = viewModel?.version.value == 5
            return header
        case .alerts:
            // swiftlint:disable force_cast
            let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: alertsSectionHeaderReuseIdentifier)
                as! TagSettingsAlertsHeaderFooterView
            // swiftlint:enable force_cast
            header.delegate = self
            let isPN = viewModel?.isPushNotificationsEnabled.value ?? false
            let isCo = viewModel?.isConnected.value ?? false
            header.disabledView.isHidden = isPN && isCo
            return header
        default:
            return nil
        }
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let s = TagSettingsTableSection.section(for: section)
        switch s {
        case .moreInfo:
            return 44
        case .alerts:
            return TagSettingsTableSection.showAlerts(for: viewModel) ? 44 : .leastNormalMagnitude
        case .connection:
            return TagSettingsTableSection.showConnection(for: viewModel)
                ? super.tableView(tableView, heightForHeaderInSection: section) : .leastNormalMagnitude
        default:
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let s = TagSettingsTableSection.section(for: section)
        switch s {
        case .alerts:
            return TagSettingsTableSection.showAlerts(for: viewModel)
                ? super.tableView(tableView, heightForHeaderInSection: section) : .leastNormalMagnitude
        case .connection:
            return TagSettingsTableSection.showConnection(for: viewModel)
                ? super.tableView(tableView, heightForHeaderInSection: section) : .leastNormalMagnitude
        default:
            return super.tableView(tableView, heightForHeaderInSection: section)
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = TagSettingsTableSection.section(for: section)
        switch s {
        case .alerts:
            return TagSettingsTableSection.showAlerts(for: viewModel)
                ? super.tableView(tableView, numberOfRowsInSection: section) : 0
        case .connection:
            return TagSettingsTableSection.showConnection(for: viewModel)
                ? super.tableView(tableView, numberOfRowsInSection: section) : 0
        default:
            return super.tableView(tableView, numberOfRowsInSection: section)
        }
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        if viewModel?.isConnectable.value == true {
            let headerHeight: CGFloat = 66
            let controlsHeight: CGFloat = 148
            let descriptionHeight: CGFloat = 60
            switch cell {
            case temperatureAlertHeaderCell,
                 humidityAlertHeaderCell,
                 dewPointAlertHeaderCell,
                 pressureAlertHeaderCell,
                 connectionAlertHeaderCell,
                 movementAlertHeaderCell:
                return headerHeight
            case temperatureAlertControlsCell:
                return (viewModel?.isTemperatureAlertOn.value ?? false) ? controlsHeight : 0
            case humidityAlertControlsCell:
                return (viewModel?.isHumidityAlertOn.value ?? false) ? controlsHeight : 0
            case dewPointAlertControlsCell:
                return (viewModel?.isDewPointAlertOn.value ?? false) ? controlsHeight : 0
            case pressureAlertControlsCell:
                return (viewModel?.isPressureAlertOn.value ?? false) ? controlsHeight : 0
            case connectionAlertDescriptionCell:
                return (viewModel?.isConnectionAlertOn.value ?? false) ? descriptionHeight : 0
            case movementAlertDescriptionCell:
                return (viewModel?.isMovementAlertOn.value ?? false) ? descriptionHeight : 0
            default:
                return 44
            }
        } else {
            switch cell {
            case temperatureAlertHeaderCell,
                 temperatureAlertControlsCell,
                 humidityAlertHeaderCell,
                 humidityAlertControlsCell,
                 dewPointAlertHeaderCell,
                 dewPointAlertControlsCell,
                 pressureAlertHeaderCell,
                 pressureAlertControlsCell,
                 connectionAlertHeaderCell,
                 connectionAlertDescriptionCell,
                 movementAlertHeaderCell,
                 movementAlertDescriptionCell:
                return 0
            default:
                return 44
            }
        }
    }
}

// MARK: - TagSettingsAlertsHeaderFooterViewDelegate
extension TagSettingsTableViewController: TagSettingsAlertsHeaderFooterViewDelegate {
    func tagSettingsAlerts(headerView: TagSettingsAlertsHeaderFooterView, didTapOnDisabled button: UIButton) {
        output.viewDidTapOnAlertsDisabledView()
    }
}

// MARK: - TagSettingsMoreInfoHeaderFooterViewDelegate
extension TagSettingsTableViewController: TagSettingsMoreInfoHeaderFooterViewDelegate {
    func tagSettingsMoreInfo(headerView: TagSettingsMoreInfoHeaderFooterView, didTapOnInfo button: UIButton) {
        output.viewDidTapOnNoValuesView()
    }
}

// MARK: - TagSettingsAlertHeaderCellDelegate
extension TagSettingsTableViewController: TagSettingsAlertHeaderCellDelegate {
    func tagSettingsAlertHeader(cell: TagSettingsAlertHeaderCell, didToggle isOn: Bool) {
        switch cell {
        case temperatureAlertHeaderCell:
            viewModel?.isTemperatureAlertOn.value = isOn
        case humidityAlertHeaderCell:
            viewModel?.isHumidityAlertOn.value = isOn
        case dewPointAlertHeaderCell:
            viewModel?.isDewPointAlertOn.value = isOn
        case pressureAlertHeaderCell:
            viewModel?.isPressureAlertOn.value = isOn
        case connectionAlertHeaderCell:
            viewModel?.isConnectionAlertOn.value = isOn
        case movementAlertHeaderCell:
            viewModel?.isMovementAlertOn.value = isOn
        default:
            break
        }
    }
}

// MARK: - TagSettingsAlertDescriptionCellDelegate
extension TagSettingsTableViewController: TagSettingsAlertDescriptionCellDelegate {
    func tagSettingsAlertDescription(cell: TagSettingsAlertDescriptionCell, didEnter description: String?) {
        switch cell {
        case connectionAlertDescriptionCell:
            viewModel?.connectionAlertDescription.value = description
        case movementAlertDescriptionCell:
            viewModel?.movementAlertDescription.value = description
        default:
            break
        }
    }
}

// MARK: - TagSettingsAlertControlsCellDelegate
extension TagSettingsTableViewController: TagSettingsAlertControlsCellDelegate {
    func tagSettingsAlertControls(cell: TagSettingsAlertControlsCell, didEnter description: String?) {
        switch cell {
        case temperatureAlertControlsCell:
            viewModel?.temperatureAlertDescription.value = description
        case humidityAlertControlsCell:
            viewModel?.humidityAlertDescription.value = description
        case dewPointAlertControlsCell:
            viewModel?.dewPointAlertDescription.value = description
        case pressureAlertControlsCell:
            viewModel?.pressureAlertDescription.value = description
        default:
            break
        }
    }

    func tagSettingsAlertControls(cell: TagSettingsAlertControlsCell, didSlideTo minValue: CGFloat, maxValue: CGFloat) {
        switch cell {
        case temperatureAlertControlsCell:
            if let tu = viewModel?.temperatureUnit.value {
                viewModel?.temperatureLowerBound.value = Temperature(Double(minValue), unit: tu.unitTemperature)
                viewModel?.temperatureUpperBound.value = Temperature(Double(maxValue), unit: tu.unitTemperature)
            }
        case humidityAlertControlsCell:
            if let hu = viewModel?.humidityUnit.value,
               let t = viewModel?.temperature.value {
                switch hu {
                case .gm3:
                    viewModel?.humidityLowerBound.value = Humidity(value: Double(minValue), unit: .absolute)
                    viewModel?.humidityUpperBound.value = Humidity(value: Double(maxValue), unit: .absolute)
                default:
                    viewModel?.humidityLowerBound.value = Humidity(value: Double(minValue / 100.0),
                                                                   unit: .relative(temperature: t))
                    viewModel?.humidityUpperBound.value = Humidity(value: Double(maxValue / 100.0),
                                                                   unit: .relative(temperature: t))
                }
            }
        case dewPointAlertControlsCell:
            if let tu = viewModel?.temperatureUnit.value {
                viewModel?.dewPointLowerBound.value = Temperature(Double(minValue), unit: tu.unitTemperature)
                viewModel?.dewPointUpperBound.value = Temperature(Double(maxValue), unit: tu.unitTemperature)
            }
        case pressureAlertControlsCell:
            if let pu = viewModel?.pressureUnit.value {
                viewModel?.pressureLowerBound.value = Pressure(Double(minValue), unit: pu)
                viewModel?.pressureUpperBound.value = Pressure(Double(maxValue), unit: pu)
            }
        default:
            break
        }
    }
}

// MARK: - View configuration
extension TagSettingsTableViewController {
    private func configureViews() {
        let moreInfoSectionNib = UINib(nibName: "TagSettingsMoreInfoHeaderFooterView", bundle: nil)
        tableView.register(moreInfoSectionNib, forHeaderFooterViewReuseIdentifier: moreInfoSectionHeaderReuseIdentifier)
        let alertsSectionNib = UINib(nibName: "TagSettingsAlertsHeaderFooterView", bundle: nil)
        tableView.register(alertsSectionNib, forHeaderFooterViewReuseIdentifier: alertsSectionHeaderReuseIdentifier)
        temperatureAlertHeaderCell.delegate = self
        temperatureAlertControlsCell.delegate = self
        humidityAlertHeaderCell.delegate = self
        humidityAlertControlsCell.delegate = self
        dewPointAlertHeaderCell.delegate = self
        dewPointAlertControlsCell.delegate = self
        pressureAlertHeaderCell.delegate = self
        pressureAlertControlsCell.delegate = self
        connectionAlertHeaderCell.delegate = self
        connectionAlertDescriptionCell.delegate = self
        movementAlertHeaderCell.delegate = self
        movementAlertDescriptionCell.delegate = self
        configureMinMaxForSliders()
    }

    private func configureMinMaxForSliders() {
        let tu = viewModel?.temperatureUnit.value ?? .celsius
        temperatureAlertControlsCell.slider.minValue = CGFloat(tu.alertRange.lowerBound)
        temperatureAlertControlsCell.slider.maxValue = CGFloat(tu.alertRange.upperBound)

        let hu = viewModel?.humidityUnit.value ?? .percent
        humidityAlertControlsCell.slider.minValue = CGFloat(hu.alertRange.lowerBound)
        humidityAlertControlsCell.slider.maxValue = CGFloat(hu.alertRange.upperBound)

        let p = viewModel?.pressureUnit.value ?? .hectopascals
        pressureAlertControlsCell.slider.minValue = CGFloat(p.alertRange.lowerBound)
        pressureAlertControlsCell.slider.maxValue = CGFloat(p.alertRange.upperBound)

        dewPointAlertControlsCell.slider.minValue = CGFloat(tu.alertRange.lowerBound)
        dewPointAlertControlsCell.slider.maxValue = CGFloat(tu.alertRange.upperBound)
    }
}

// MARK: - Bindings
extension TagSettingsTableViewController {
    private func bindViewModels() {
        bindViewModel()
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    private func bindViewModel() {
        bindHumidity()
        bindTemperatureAlertCells()
        bindHumidityAlertCells()
        bindDewPointAlertCells()
        bindPressureAlertCells()
        bindConnectionAlertCells()
        bindMovementAlertCell()
        guard isViewLoaded, let viewModel = viewModel  else { return }

        dataSourceValueLabel.bind(viewModel.isConnected) { (label, isConnected) in
            if let isConnected = isConnected, isConnected {
                label.text = "TagSettings.DataSource.Heartbeat.title".localized()
            } else {
                label.text = "TagSettings.DataSource.Advertisement.title".localized()
            }
        }

        tableView.bind(viewModel.version) { (tableView, _) in
            tableView.reloadData()
        }

        tableView.bind(viewModel.humidityUnit) { tableView, _ in
            tableView.reloadData()
        }

        backgroundImageView.bind(viewModel.background) { $0.image = $1 }
        tagNameTextField.bind(viewModel.name) { $0.text = $1 }

        let emptyValueString = "TagSettings.EmptyValue.sign"

        uuidValueLabel.bind(viewModel.uuid) { label, uuid in
            if let uuid = uuid {
                label.text = uuid
            } else {
                label.text = emptyValueString.localized()
            }
        }

        macAddressValueLabel.bind(viewModel.mac) { label, mac in
            if let mac = mac {
                label.text = mac
            } else {
                label.text = emptyValueString.localized()
            }
        }

        voltageValueLabel.bind(viewModel.voltage) { label, voltage in
            if let voltage = voltage {
                label.text = String.localizedStringWithFormat("%.3f", voltage) + " " + "V".localized()
            } else {
                label.text = emptyValueString.localized()
            }
        }

        accelerationXValueLabel.bind(viewModel.accelerationX) { label, accelerationX in
            if let accelerationX = accelerationX {
                label.text = String.localizedStringWithFormat("%.3f", accelerationX) + " " + "g".localized()
            } else {
                label.text = emptyValueString.localized()
            }
        }

        accelerationYValueLabel.bind(viewModel.accelerationY) { label, accelerationY in
            if let accelerationY = accelerationY {
                label.text = String.localizedStringWithFormat("%.3f", accelerationY) + " " + "g".localized()
            } else {
                label.text = emptyValueString.localized()
            }
        }

        accelerationZValueLabel.bind(viewModel.accelerationZ) { label, accelerationZ in
            if let accelerationZ = accelerationZ {
                label.text = String.localizedStringWithFormat("%.3f", accelerationZ) + " " + "g".localized()
            } else {
                label.text = emptyValueString.localized()
            }
        }

        dataFormatValueLabel.bind(viewModel.version) { (label, version) in
            if let version = version {
                label.text = "\(version)"
            } else {
                label.text = emptyValueString.localized()
            }
        }

        mcValueLabel.bind(viewModel.movementCounter) { (label, mc) in
            if let mc = mc {
                label.text = "\(mc)"
            } else {
                label.text = emptyValueString.localized()
            }
        }

        msnValueLabel.bind(viewModel.measurementSequenceNumber) { (label, msn) in
            if let msn = msn {
                label.text = "\(msn)"
            } else {
                label.text = emptyValueString.localized()
            }
        }

        txPowerValueLabel.bind(viewModel.txPower) { (label, txPower) in
            if let txPower = txPower {
                label.text = "\(txPower)" + " " + "dBm".localized()
            } else {
                label.text = emptyValueString.localized()
            }
        }

        tableView.bind(viewModel.isConnectable) { (tableView, _) in
            tableView.reloadData()
        }

        tableView.bind(viewModel.isConnected) { (tableView, _) in
            tableView.reloadData()
        }

        tableView.bind(viewModel.isPushNotificationsEnabled) { (tableView, _) in
            tableView.reloadData()
        }

        let keepConnection = viewModel.keepConnection
        connectStatusLabel.bind(viewModel.isConnected) { [weak keepConnection] (label, isConnected) in
            let keep = keepConnection?.value ?? false
            if isConnected.bound {
                label.text = "TagSettings.ConnectStatus.Connected".localized()
            } else if keep {
                label.text = "TagSettings.ConnectStatus.Connecting".localized()
            } else {
                label.text = "TagSettings.ConnectStatus.Disconnected".localized()
            }
        }

        let isConnected = viewModel.isConnected

        keepConnectionSwitch.bind(viewModel.keepConnection) { (view, keepConnection) in
            view.isOn = keepConnection.bound
        }

        connectStatusLabel.bind(viewModel.keepConnection) { [weak isConnected] (label, keepConnection) in
            let isConnected = isConnected?.value ?? false
            if isConnected {
                label.text = "TagSettings.ConnectStatus.Connected".localized()
            } else if keepConnection.bound {
                label.text = "TagSettings.ConnectStatus.Connecting".localized()
            } else {
                label.text = "TagSettings.ConnectStatus.Disconnected".localized()
            }
        }
    }

    private func bindHumidity() {
        guard isViewLoaded, let viewModel = viewModel else { return }
        let temperature = viewModel.temperature.value
        let humidity = viewModel.humidity.value
        let humidityOffset = viewModel.humidityOffset.value
        let humidityCell = calibrationHumidityCell
        let humidityTrailing = humidityLabelTrailing

        let humidityBlock: ((UILabel, Any?) -> Void) = {
            [weak humidityCell,
             weak humidityTrailing] label, _ in
            // TODO with use measurement service
            if let temperature = temperature,
               let humidityOffset = humidityOffset,
               let humidity = humidity?.converted(to: .relative(temperature: temperature)).value {
                if humidityOffset > 0 {
                    let shownHumidity = humidity + humidityOffset
                    if shownHumidity > 100.0 {
                        label.text = "\(String.localizedStringWithFormat("%.2f", humidity))"
                            + " → " + "\(String.localizedStringWithFormat("%.2f", 100.0))"
                        humidityCell?.accessoryType = .detailButton
                        humidityTrailing?.constant = 0
                    } else {
                        label.text = "\(String.localizedStringWithFormat("%.2f", humidity))"
                            + " → " + "\(String.localizedStringWithFormat("%.2f", shownHumidity))"
                        humidityCell?.accessoryType = .none
                        humidityTrailing?.constant = 16.0
                    }
                } else {
                    label.text = nil
                    humidityCell?.accessoryType = .none
                    humidityTrailing?.constant = 16.0
                }
            } else {
                label.text = nil
            }
        }
        humidityLabel.bind(viewModel.humidity, block: humidityBlock)
        humidityLabel.bind(viewModel.humidityOffset, block: humidityBlock)
    }

    // swiftlint:disable:next function_body_length
    private func bindTemperatureAlertCells() {
        guard isViewLoaded, let viewModel = viewModel  else { return }
        temperatureAlertHeaderCell.isOnSwitch.bind(viewModel.isTemperatureAlertOn) { (view, isOn) in
            view.isOn = isOn.bound
        }
        temperatureAlertControlsCell.slider.bind(viewModel.isTemperatureAlertOn) { (slider, isOn) in
            slider.isEnabled = isOn.bound
        }

        temperatureAlertControlsCell.slider.bind(viewModel.temperatureLowerBound) { [weak self] (_, _) in
            self?.updateUITemperatureLowerBound()
            self?.updateUITemperatureAlertDescription()
        }
        temperatureAlertControlsCell.slider.bind(viewModel.temperatureUpperBound) { [weak self] (_, _) in
            self?.updateUITemperatureUpperBound()
            self?.updateUITemperatureAlertDescription()
        }

        temperatureAlertHeaderCell.titleLabel.bind(viewModel.temperatureUnit) { (label, temperatureUnit) in
            let title = "TagSettings.temperatureAlertTitleLabel.text"
            label.text = title.localized()
                + " "
                + (temperatureUnit?.symbol ?? "N/A".localized())
        }

        temperatureAlertControlsCell.slider.bind(viewModel.temperatureUnit) { (slider, temperatureUnit) in
            if let tu = temperatureUnit {
                slider.minValue = CGFloat(tu.alertRange.lowerBound)
                slider.maxValue = CGFloat(tu.alertRange.upperBound)
            }
        }

        temperatureAlertHeaderCell.descriptionLabel.bind(viewModel.isTemperatureAlertOn) { [weak self] (_, _) in
            self?.updateUITemperatureAlertDescription()
        }

        let isPNEnabled = viewModel.isPushNotificationsEnabled
        let isTemperatureAlertOn = viewModel.isTemperatureAlertOn
        let isConnected = viewModel.isConnected

        temperatureAlertHeaderCell.isOnSwitch.bind(viewModel.isConnected) {
            [weak isPNEnabled] (view, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isEnabled = isPN && isConnected.bound
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        temperatureAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
            [weak isConnected] view, isPushNotificationsEnabled in
            let isPN = isPushNotificationsEnabled ?? false
            let isCo = isConnected?.value ?? false
            let isEnabled = isPN && isCo
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        temperatureAlertControlsCell.slider.bind(viewModel.isConnected) {
            [weak isTemperatureAlertOn, weak isPNEnabled] (slider, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isOn = isTemperatureAlertOn?.value ?? false
            slider.isEnabled = isConnected.bound && isOn && isPN
        }

        temperatureAlertControlsCell.slider.bind(viewModel.isPushNotificationsEnabled) {
            [weak isTemperatureAlertOn, weak isConnected] (slider, isPushNotificationsEnabled) in
            let isOn = isTemperatureAlertOn?.value ?? false
            let isCo = isConnected?.value ?? false
            slider.isEnabled = isPushNotificationsEnabled.bound && isOn && isCo
        }

        temperatureAlertControlsCell.textField.bind(viewModel.temperatureAlertDescription) {
            (textField, temperatureAlertDescription) in
            textField.text = temperatureAlertDescription
        }

        tableView.bind(viewModel.isTemperatureAlertOn) { tableView, _ in
            if tableView.window != nil {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    private func bindConnectionAlertCells() {
        guard isViewLoaded, let viewModel = viewModel  else { return }
        connectionAlertHeaderCell.isOnSwitch.bind(viewModel.isConnectionAlertOn) { (view, isOn) in
            view.isOn = isOn.bound
        }

        connectionAlertHeaderCell.descriptionLabel.bind(viewModel.isConnectionAlertOn) { [weak self] (_, _) in
            self?.updateUIConnectionAlertDescription()
        }

        connectionAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
            view, isPushNotificationsEnabled in
            let isPN = isPushNotificationsEnabled ?? false
            let isEnabled = isPN
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        connectionAlertDescriptionCell.textField.bind(viewModel.connectionAlertDescription) {
            (textField, connectionAlertDescription) in
            textField.text = connectionAlertDescription
        }

        tableView.bind(viewModel.isConnectionAlertOn) { tableView, _ in
            if tableView.window != nil {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    private func bindMovementAlertCell() {
        guard isViewLoaded, let viewModel = viewModel  else { return }
        movementAlertHeaderCell.isOnSwitch.bind(viewModel.isMovementAlertOn) { (view, isOn) in
            view.isOn = isOn.bound
        }

        movementAlertHeaderCell.descriptionLabel.bind(viewModel.isMovementAlertOn) { [weak self] (_, _) in
            self?.updateUIMovementAlertDescription()
        }

        let isPNEnabled = viewModel.isPushNotificationsEnabled
        let isConnected = viewModel.isConnected

        movementAlertHeaderCell.isOnSwitch.bind(viewModel.isConnected) { [weak isPNEnabled] (view, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isEnabled = isPN && isConnected.bound
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        movementAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
            [weak isConnected] view, isPushNotificationsEnabled in
            let isPN = isPushNotificationsEnabled ?? false
            let isCo = isConnected?.value ?? false
            let isEnabled = isPN && isCo
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        movementAlertDescriptionCell.textField.bind(viewModel.movementAlertDescription) {
            (textField, movementAlertDescription) in
            textField.text = movementAlertDescription
        }

        tableView.bind(viewModel.isMovementAlertOn) { tableView, _ in
            if tableView.window != nil {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func bindPressureAlertCells() {
        guard isViewLoaded, let viewModel = viewModel  else { return }
        pressureAlertHeaderCell.isOnSwitch.bind(viewModel.isPressureAlertOn) { (view, isOn) in
            view.isOn = isOn.bound
        }

        pressureAlertControlsCell.slider.bind(viewModel.isPressureAlertOn) { (slider, isOn) in
            slider.isEnabled = isOn.bound
        }

        pressureAlertControlsCell.slider.bind(viewModel.pressureLowerBound) { [weak self] (_, _) in
            self?.updateUIPressureLowerBound()
            self?.updateUIPressureAlertDescription()
        }

        pressureAlertControlsCell.slider.bind(viewModel.pressureUpperBound) { [weak self] (_, _) in
            self?.updateUIPressureUpperBound()
            self?.updateUIPressureAlertDescription()
        }

        pressureAlertHeaderCell.titleLabel.bind(viewModel.pressureUnit) { (label, pressureUnit) in
            let title = "TagSettings.PressureAlert.title"
            label.text = title.localized()
                + " "
                + (pressureUnit?.symbol ?? "N/A".localized())
        }

        pressureAlertControlsCell.slider.bind(viewModel.pressureUnit) { (slider, pressureUnit) in
            if let pu = pressureUnit {
                slider.minValue = CGFloat(pu.alertRange.lowerBound)
                slider.maxValue = CGFloat(pu.alertRange.upperBound)
            }
        }

        pressureAlertHeaderCell.descriptionLabel.bind(viewModel.isPressureAlertOn) { [weak self] (_, _) in
            self?.updateUIPressureAlertDescription()
        }

        let isPNEnabled = viewModel.isPushNotificationsEnabled
        let isPressureAlertOn = viewModel.isPressureAlertOn
        let isConnected = viewModel.isConnected

        pressureAlertHeaderCell.isOnSwitch.bind(viewModel.isConnected) { [weak isPNEnabled] (view, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isEnabled = isPN && isConnected.bound
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        pressureAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
            [weak isConnected] view, isPushNotificationsEnabled in
            let isPN = isPushNotificationsEnabled ?? false
            let isCo = isConnected?.value ?? false
            let isEnabled = isPN && isCo
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        pressureAlertControlsCell.slider.bind(viewModel.isConnected) {
            [weak isPressureAlertOn, weak isPNEnabled] (slider, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isOn = isPressureAlertOn?.value ?? false
            slider.isEnabled = isConnected.bound && isOn && isPN
        }

        pressureAlertControlsCell.slider.bind(viewModel.isPushNotificationsEnabled) {
            [weak isPressureAlertOn, weak isConnected] (slider, isPushNotificationsEnabled) in
            let isOn = isPressureAlertOn?.value ?? false
            let isCo = isConnected?.value ?? false
            slider.isEnabled = isPushNotificationsEnabled.bound && isOn && isCo
        }

        pressureAlertControlsCell.textField.bind(viewModel.pressureAlertDescription) {
            (textField, pressureAlertDescription) in
            textField.text = pressureAlertDescription
        }

        tableView.bind(viewModel.isPressureAlertOn) { tableView, _ in
            if tableView.window != nil {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func bindHumidityAlertCells() {
        guard isViewLoaded, let viewModel = viewModel  else { return }
        humidityAlertHeaderCell.isOnSwitch.bind(viewModel.isHumidityAlertOn) { (view, isOn) in
            view.isOn = isOn.bound
        }

        humidityAlertControlsCell.slider.bind(viewModel.isHumidityAlertOn) { (slider, isOn) in
            slider.isEnabled = isOn.bound
        }

        humidityAlertControlsCell.slider.bind(viewModel.humidityLowerBound) { [weak self] (_, _) in
            self?.updateUIHumidityLowerBound()
            self?.updateUIHumidityAlertDescription()
        }

        humidityAlertControlsCell.slider.bind(viewModel.humidityUpperBound) { [weak self] (_, _) in
            self?.updateUIHumidityUpperBound()
            self?.updateUIHumidityAlertDescription()
        }

        humidityAlertHeaderCell.titleLabel.bind(viewModel.humidityUnit) { (label, humidityUnit) in
            let title = "TagSettings.AirHumidityAlert.title"
            let symbol = humidityUnit == .dew ? HumidityUnit.percent.symbol : humidityUnit?.symbol
            label.text = title.localized()
                + " "
                + (symbol ?? "N/A".localized())
        }

        humidityAlertControlsCell.slider.bind(viewModel.humidityUnit) { (slider, humidityUnit) in
            if let hu = humidityUnit {
                slider.minValue = CGFloat(hu.alertRange.lowerBound)
                slider.maxValue = CGFloat(hu.alertRange.upperBound)
            }
        }

        humidityAlertHeaderCell.descriptionLabel.bind(viewModel.isHumidityAlertOn) {
            [weak self] (_, _) in
            self?.updateUIHumidityAlertDescription()
        }

        let isPNEnabled = viewModel.isPushNotificationsEnabled
        let isHumidityAlertOn = viewModel.isHumidityAlertOn
        let isConnected = viewModel.isConnected

        humidityAlertHeaderCell.isOnSwitch.bind(viewModel.isConnected) {
            [weak isPNEnabled] (view, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isEnabled = isPN && isConnected.bound
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        humidityAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
            [weak isConnected] view, isPushNotificationsEnabled in
            let isPN = isPushNotificationsEnabled ?? false
            let isCo = isConnected?.value ?? false
            let isEnabled = isPN && isCo
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        humidityAlertControlsCell.slider.bind(viewModel.isConnected) {
            [weak isHumidityAlertOn, weak isPNEnabled] (slider, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isOn = isHumidityAlertOn?.value ?? false
            slider.isEnabled = isConnected.bound && isOn && isPN
        }

        humidityAlertControlsCell.slider.bind(viewModel.isPushNotificationsEnabled) {
            [weak isHumidityAlertOn, weak isConnected] (slider, isPushNotificationsEnabled) in
            let isOn = isHumidityAlertOn?.value ?? false
            let isCo = isConnected?.value ?? false
            slider.isEnabled = isPushNotificationsEnabled.bound && isOn && isCo
        }

        humidityAlertControlsCell.textField.bind(viewModel.humidityAlertDescription) {
            (textField, humidityAlertDescription) in
            textField.text = humidityAlertDescription
        }

        tableView.bind(viewModel.isHumidityAlertOn) { tableView, _ in
            if tableView.window != nil {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }

    // swiftlint:disable:next function_body_length
    private func bindDewPointAlertCells() {
        guard isViewLoaded, let viewModel = viewModel else {
            return
        }
        dewPointAlertHeaderCell.isOnSwitch.bind(viewModel.isDewPointAlertOn) { (view, isOn) in
            view.isOn = isOn.bound
        }

        dewPointAlertControlsCell.slider.bind(viewModel.isDewPointAlertOn) { (slider, isOn) in
            slider.isEnabled = isOn.bound
        }

        dewPointAlertControlsCell.slider.bind(viewModel.dewPointLowerBound) { [weak self] (_, _) in
            self?.updateUIDewPointCelsiusLowerBound()
            self?.updateUIDewPointAlertDescription()
        }

        dewPointAlertControlsCell.slider.bind(viewModel.dewPointUpperBound) { [weak self] (_, _) in
            self?.updateUIDewPointCelsiusUpperBound()
            self?.updateUIDewPointAlertDescription()
        }

        dewPointAlertHeaderCell.titleLabel.bind(viewModel.temperatureUnit) { (label, temperatureUnit) in
            let title = "TagSettings.dewPointAlertTitleLabel.text"
            label.text = title.localized()
                + " "
                + (temperatureUnit?.symbol ?? "N/A".localized())
        }

        dewPointAlertControlsCell.slider.bind(viewModel.temperatureUnit) { (slider, temperatureUnit) in
            if let tu = temperatureUnit {
                slider.minValue = CGFloat(tu.alertRange.lowerBound)
                slider.maxValue = CGFloat(tu.alertRange.upperBound)
            }
        }

        dewPointAlertHeaderCell.descriptionLabel.bind(viewModel.isDewPointAlertOn) { [weak self] (_, _) in
            self?.updateUIDewPointAlertDescription()
        }

        let isPNEnabled = viewModel.isPushNotificationsEnabled
        let isDewPointAlertOn = viewModel.isDewPointAlertOn
        let isConnected = viewModel.isConnected

        dewPointAlertHeaderCell.isOnSwitch.bind(viewModel.isConnected) { [weak isPNEnabled] (view, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isEnabled = isPN && isConnected.bound
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        dewPointAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
            [weak isConnected] view, isPushNotificationsEnabled in
            let isPN = isPushNotificationsEnabled ?? false
            let isCo = isConnected?.value ?? false
            let isEnabled = isPN && isCo
            view.isEnabled = isEnabled
            view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
        }

        dewPointAlertControlsCell.slider.bind(viewModel.isConnected) {
            [weak isDewPointAlertOn, weak isPNEnabled] (slider, isConnected) in
            let isPN = isPNEnabled?.value ?? false
            let isOn = isDewPointAlertOn?.value ?? false
            slider.isEnabled = isConnected.bound && isOn && isPN
        }

        dewPointAlertControlsCell.slider.bind(viewModel.isPushNotificationsEnabled) {
            [weak isDewPointAlertOn, weak isConnected] (slider, isPushNotificationsEnabled) in
            let isOn = isDewPointAlertOn?.value ?? false
            let isCo = isConnected?.value ?? false
            slider.isEnabled = isPushNotificationsEnabled.bound && isOn && isCo
        }

        dewPointAlertControlsCell.textField.bind(viewModel.dewPointAlertDescription) {
            (textField, dewPointAlertDescription) in
            textField.text = dewPointAlertDescription
        }

        tableView.bind(viewModel.isDewPointAlertOn) { tableView, _ in
            if tableView.window != nil {
                tableView.beginUpdates()
                tableView.endUpdates()
            }
        }
    }
}

// MARK: - UITextFieldDelegate
extension TagSettingsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

// MARK: - Update UI
extension TagSettingsTableViewController {
    private func updateUI() {
        updateUITemperatureAlertDescription()
        updateUITemperatureLowerBound()
        updateUITemperatureUpperBound()

        updateUIHumidityAlertDescription()
        updateUIHumidityLowerBound()
        updateUIHumidityUpperBound()

        updateUIPressureAlertDescription()
        updateUIPressureLowerBound()
        updateUIPressureUpperBound()

        updateUIDewPointAlertDescription()
        updateUIDewPointCelsiusLowerBound()
        updateUIDewPointCelsiusUpperBound()
    }
    // MARK: - updateUITemperature

    private func updateUITemperatureLowerBound() {
        guard isViewLoaded else { return }
        guard let temperatureUnit = viewModel?.temperatureUnit.value else {
            let range = TemperatureUnit.celsius.alertRange
            temperatureAlertControlsCell.slider.minValue = CGFloat(range.lowerBound)
            temperatureAlertControlsCell.slider.selectedMinValue = CGFloat(range.lowerBound)
            return
        }
        if let lower = viewModel?.temperatureLowerBound.value?.converted(to: temperatureUnit.unitTemperature) {
            temperatureAlertControlsCell.slider.selectedMinValue = CGFloat(lower.value)
        } else {
            let lower: CGFloat = CGFloat(temperatureUnit.alertRange.lowerBound)
            temperatureAlertControlsCell.slider.selectedMinValue = lower
        }
    }

    private func updateUITemperatureUpperBound() {
        guard isViewLoaded else { return }
        guard let temperatureUnit = viewModel?.temperatureUnit.value else {
            let range = TemperatureUnit.celsius.alertRange
            temperatureAlertControlsCell.slider.maxValue = CGFloat(range.upperBound)
            temperatureAlertControlsCell.slider.selectedMaxValue = CGFloat(range.upperBound)
            return
        }
        if let upper = viewModel?.temperatureUpperBound.value?.converted(to: temperatureUnit.unitTemperature) {
            temperatureAlertControlsCell.slider.selectedMaxValue = CGFloat(upper.value)
        } else {
            let upper: CGFloat = CGFloat(temperatureUnit.alertRange.upperBound)
            temperatureAlertControlsCell.slider.selectedMaxValue = upper
        }
    }

    private func updateUITemperatureAlertDescription() {
        guard isViewLoaded else { return }
        guard viewModel?.isTemperatureAlertOn.value == true else {
            temperatureAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
            return
        }
        if let tu = viewModel?.temperatureUnit.value?.unitTemperature,
           let l = viewModel?.temperatureLowerBound.value?.converted(to: tu),
           let u = viewModel?.temperatureUpperBound.value?.converted(to: tu) {
            let format = "TagSettings.Alerts.Temperature.description".localized()
            temperatureAlertHeaderCell.descriptionLabel.text = String(format: format, l.value, u.value)
        } else {
            temperatureAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
        }
    }
    // MARK: - updateUIHumidity
    private func updateUIHumidityLowerBound() {
        guard isViewLoaded else { return }
        guard let hu = viewModel?.humidityUnit.value else {
            let range = HumidityUnit.gm3.alertRange
            humidityAlertControlsCell.slider.minValue = CGFloat(range.lowerBound)
            humidityAlertControlsCell.slider.selectedMinValue = CGFloat(range.lowerBound)
            return
        }
        if let lower = viewModel?.humidityLowerBound.value {
            switch hu {
            case .gm3:
                let lowerAbsolute: Double = max(lower.converted(to: .absolute).value, hu.alertRange.lowerBound)
                humidityAlertControlsCell.slider.selectedMinValue = CGFloat(lowerAbsolute)
            default:
                if let t = viewModel?.temperature.value {
                    let minValue: Double = lower.converted(to: .relative(temperature: t)).value
                    let lowerRelative: Double = min(
                        max(minValue * 100, HumidityUnit.percent.alertRange.lowerBound),
                        HumidityUnit.percent.alertRange.upperBound
                    )
                    humidityAlertControlsCell.slider.selectedMinValue = CGFloat(lowerRelative)
                } else {
                    humidityAlertControlsCell.slider.selectedMinValue = CGFloat(hu.alertRange.lowerBound)
                }
            }
        } else {
            humidityAlertControlsCell.slider.selectedMinValue = CGFloat(hu.alertRange.lowerBound)
        }
    }

    private func updateUIHumidityUpperBound() {
        guard isViewLoaded else { return }
        guard let hu = viewModel?.humidityUnit.value else {
            let range = HumidityUnit.gm3.alertRange
            humidityAlertControlsCell.slider.maxValue = CGFloat(range.upperBound)
            humidityAlertControlsCell.slider.selectedMaxValue = CGFloat(range.upperBound)
            return
        }
        if let upper = viewModel?.humidityUpperBound.value {
            switch hu {
            case .gm3:
                let upperAbsolute: Double = min(upper.converted(to: .absolute).value, hu.alertRange.upperBound)
                humidityAlertControlsCell.slider.selectedMaxValue = CGFloat(upperAbsolute)
            default:
                if let t = viewModel?.temperature.value {
                    let maxValue: Double = upper.converted(to: .relative(temperature: t)).value
                    let upperRelative: Double = min(maxValue * 100, HumidityUnit.percent.alertRange.upperBound)
                    humidityAlertControlsCell.slider.selectedMaxValue = CGFloat(upperRelative)
                } else {
                    humidityAlertControlsCell.slider.selectedMaxValue = CGFloat(hu.alertRange.upperBound)
                }
            }
        } else {
            humidityAlertControlsCell.slider.selectedMaxValue = CGFloat(hu.alertRange.upperBound)
        }
    }

    private func updateUIHumidityAlertDescription() {
        guard isViewLoaded else { return }
        guard let isHumidityAlertOn = viewModel?.isHumidityAlertOn.value,
              isHumidityAlertOn else {
            humidityAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
            return
        }
        if let hu = viewModel?.humidityUnit.value,
           let l = viewModel?.humidityLowerBound.value,
           let u = viewModel?.humidityUpperBound.value {
            let format = "TagSettings.Alerts.Humidity.description".localized()
            let description: String
            if hu == .gm3 {
                let la: Double = max(l.converted(to: .absolute).value, hu.alertRange.lowerBound)
                let ua: Double = min(u.converted(to: .absolute).value, hu.alertRange.upperBound)
                description = String(format: format, la, ua)
            } else {
                if let t = viewModel?.temperature.value {
                    let lv: Double = l.converted(to: .relative(temperature: t)).value * 100.0
                    let lr: Double = min(
                        max(lv, HumidityUnit.percent.alertRange.lowerBound),
                        HumidityUnit.percent.alertRange.upperBound
                    )
                    let ua: Double = u.converted(to: .relative(temperature: t)).value * 100.0
                    let ur: Double = max(
                        min(ua, HumidityUnit.percent.alertRange.upperBound),
                        HumidityUnit.percent.alertRange.lowerBound
                    )
                    description = String(format: format, lr, ur)
                } else {
                    description = alertOffString.localized()
                }
            }
            humidityAlertHeaderCell.descriptionLabel.text = description
        } else {
            humidityAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
        }
    }

    // MARK: - updateUIPressure
    private func updateUIPressureLowerBound() {
        guard isViewLoaded else { return }
        guard let pu = viewModel?.pressureUnit.value else {
            let range = UnitPressure.hectopascals.alertRange
            pressureAlertControlsCell.slider.minValue = CGFloat(range.lowerBound)
            pressureAlertControlsCell.slider.selectedMinValue = CGFloat(range.lowerBound)
            return
        }
        if let lower = viewModel?.pressureLowerBound.value?.converted(to: pu).value {
            let l = min(
                max(lower, pu.alertRange.lowerBound),
                pu.alertRange.upperBound
            )
            pressureAlertControlsCell.slider.selectedMinValue = CGFloat(l)
        } else {
            pressureAlertControlsCell.slider.selectedMinValue = CGFloat(pu.alertRange.lowerBound)
        }
    }

    private func updateUIPressureUpperBound() {
        guard isViewLoaded else { return }
        guard let pu = viewModel?.pressureUnit.value else {
            let range = UnitPressure.hectopascals.alertRange
            pressureAlertControlsCell.slider.maxValue =  CGFloat(range.upperBound)
            pressureAlertControlsCell.slider.selectedMaxValue =  CGFloat(range.upperBound)
            return
        }
        if let upper = viewModel?.pressureUpperBound.value?.converted(to: pu).value {
            let u = max(
                min(upper, pu.alertRange.upperBound),
                pu.alertRange.lowerBound
            )
            pressureAlertControlsCell.slider.selectedMaxValue = CGFloat(u)
        } else {
            pressureAlertControlsCell.slider.selectedMaxValue = CGFloat(pu.alertRange.upperBound)
        }
    }

    private func updateUIPressureAlertDescription() {
        guard isViewLoaded else { return }
        guard let isPressureAlertOn = viewModel?.isPressureAlertOn.value,
              isPressureAlertOn else {
            pressureAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
            return
        }
        if let pu = viewModel?.pressureUnit.value,
           let lower = viewModel?.pressureLowerBound.value?.converted(to: pu).value,
           let upper = viewModel?.pressureUpperBound.value?.converted(to: pu).value {
            let l = min(
                max(lower, pu.alertRange.lowerBound),
                pu.alertRange.upperBound
            )
            let u = max(
                min(upper, pu.alertRange.upperBound),
                pu.alertRange.lowerBound
            )
            let format = "TagSettings.Alerts.Pressure.description".localized()
            pressureAlertHeaderCell.descriptionLabel.text = String(format: format, l, u)
        } else {
            pressureAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
        }
    }

    // MARK: updateUIDewPoint

    private func updateUIDewPointCelsiusLowerBound() {
        guard isViewLoaded else { return }
        guard let temperatureUnit = viewModel?.temperatureUnit.value else {
            let range = TemperatureUnit.celsius.alertRange
            dewPointAlertControlsCell.slider.minValue = CGFloat(range.lowerBound)
            dewPointAlertControlsCell.slider.selectedMinValue = CGFloat(range.lowerBound)
            return
        }
        if let lower = viewModel?.dewPointLowerBound.value?.converted(to: temperatureUnit.unitTemperature) {
            dewPointAlertControlsCell.slider.selectedMinValue = CGFloat(lower.value)
        } else {
            let lower: CGFloat = CGFloat(temperatureUnit.alertRange.lowerBound)
            dewPointAlertControlsCell.slider.selectedMinValue = lower
        }
    }

    private func updateUIDewPointCelsiusUpperBound() {
        guard isViewLoaded else { return }
        guard let temperatureUnit = viewModel?.temperatureUnit.value else {
            dewPointAlertControlsCell.slider.maxValue = CGFloat(TemperatureUnit.celsius.alertRange.upperBound)
            dewPointAlertControlsCell.slider.selectedMaxValue = CGFloat(TemperatureUnit.celsius.alertRange.upperBound)
            return
        }
        if let upper = viewModel?.dewPointUpperBound.value?.converted(to: temperatureUnit.unitTemperature) {
            dewPointAlertControlsCell.slider.selectedMaxValue = CGFloat(upper.value)
        } else {
            let upper: CGFloat = CGFloat(temperatureUnit.alertRange.upperBound)
            dewPointAlertControlsCell.slider.selectedMaxValue = upper
        }
    }

    private func updateUIDewPointAlertDescription() {
        guard isViewLoaded else { return }
        guard viewModel?.isDewPointAlertOn.value == true else {
            dewPointAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
            return
        }
        if let tu = viewModel?.temperatureUnit.value?.unitTemperature,
           let l = viewModel?.dewPointLowerBound.value?.converted(to: tu),
           let u = viewModel?.dewPointUpperBound.value?.converted(to: tu) {
            let format = "TagSettings.Alerts.DewPoint.description".localized()
            dewPointAlertHeaderCell.descriptionLabel.text = String(format: format, l.value, u.value)
        } else {
            dewPointAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
        }
    }

    private func updateUIMovementAlertDescription() {
        guard isViewLoaded else { return }
        if let isMovementAlertOn = viewModel?.isMovementAlertOn.value, isMovementAlertOn {
            movementAlertHeaderCell.descriptionLabel.text = "TagSettings.Alerts.Movement.description".localized()
        } else {
            movementAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
        }
    }

    private func updateUIConnectionAlertDescription() {
        guard isViewLoaded else { return }
        if let isConnectionAlertOn = viewModel?.isConnectionAlertOn.value, isConnectionAlertOn {
            connectionAlertHeaderCell.descriptionLabel.text
                = "TagSettings.Alerts.Connection.description".localized()
        } else {
            connectionAlertHeaderCell.descriptionLabel.text = alertOffString.localized()
        }
    }
}
// swiftlint:enable file_length
