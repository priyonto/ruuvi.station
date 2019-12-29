// swiftlint:disable file_length
import UIKit

private enum WebTagSettingsSection: Int {
    case name = 0
    case alerts = 1
    case moreInfo = 2
}

class WebTagSettingsTableViewController: UITableViewController {
    var output: WebTagSettingsViewOutput!

    @IBOutlet weak var temperatureAlertHeaderCell: WebTagSettingsAlertHeaderCell!
    @IBOutlet weak var temperatureAlertControlsCell: WebTagSettingsAlertControlsCell!
    @IBOutlet weak var tagNameTextField: UITextField!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var tagNameCell: UITableViewCell!
    @IBOutlet weak var locationCell: UITableViewCell!
    @IBOutlet weak var locationValueLabel: UILabel!
    @IBOutlet weak var clearLocationButton: UIButton!
    @IBOutlet weak var clearLocationButtonWidth: NSLayoutConstraint!
    @IBOutlet weak var backgroundImageLabel: UILabel!
    @IBOutlet weak var tagNameTitleLabel: UILabel!
    @IBOutlet weak var removeThisWebTagButton: UIButton!
    @IBOutlet weak var locationTitleLabel: UILabel!

    var isNameChangedEnabled: Bool = true { didSet { updateUIIsNamaChangeEnabled() } }

    var viewModel = WebTagSettingsViewModel() { didSet { bindViewModel() } }
}

// MARK: - WebTagSettingsViewInput
extension WebTagSettingsTableViewController: WebTagSettingsViewInput {
    func localize() {
        navigationItem.title = "WebTagSettings.navigationItem.title".localized()
        backgroundImageLabel.text = "WebTagSettings.Label.BackgroundImage.text".localized()
        tagNameTitleLabel.text = "WebTagSettings.Label.TagName.text".localized()
        locationTitleLabel.text = "WebTagSettings.Label.Location.text".localized()
        removeThisWebTagButton.setTitle("WebTagSettings.Button.Remove.title".localized(), for: .normal)
        tableView.reloadData()
    }

    func apply(theme: Theme) {

    }

    func showTagRemovalConfirmationDialog() {
        let title = "WebTagSettings.confirmTagRemovalDialog.title".localized()
        let message = "WebTagSettings.confirmTagRemovalDialog.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Confirm".localized(),
                                           style: .destructive,
                                           handler: { [weak self] _ in
            self?.output.viewDidConfirmTagRemoval()
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

    func showClearLocationConfirmationDialog() {
        let title = "WebTagSettings.confirmClearLocationDialog.title".localized()
        let message = "WebTagSettings.confirmClearLocationDialog.message".localized()
        let controller = UIAlertController(title: title, message: message, preferredStyle: .alert)
        controller.addAction(UIAlertAction(title: "Confirm".localized(),
                                           style: .destructive,
                                           handler: { [weak self] _ in
            self?.output.viewDidConfirmToClearLocation()
        }))
        controller.addAction(UIAlertAction(title: "Cancel".localized(), style: .cancel, handler: nil))
        present(controller, animated: true)
    }

}

// MARK: - IBActions
extension WebTagSettingsTableViewController {
    @IBAction func dismissBarButtonItemAction(_ sender: Any) {
        output.viewDidAskToDismiss()
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

    @IBAction func removeThisWebTagButtonTouchUpInside(_ sender: Any) {
        output.viewDidAskToRemoveWebTag()
    }

    @IBAction func clearLocationButtonTouchUpInside(_ sender: Any) {
        output.viewDidAskToClearLocation()
    }
}

// MARK: - View lifecycle
extension WebTagSettingsTableViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        configureViews()
        setupLocalization()
        bindViewModel()
        updateUI()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        output.viewWillAppear()
    }
}

// MARK: - UITableViewDelegate
extension WebTagSettingsTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        if let cell = tableView.cellForRow(at: indexPath) {
            switch cell {
            case tagNameCell:
                tagNameTextField.becomeFirstResponder()
            case locationCell:
                output.viewDidAskToSelectLocation()
            default:
                break
            }
        }
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let headerHeight: CGFloat = 64
        let controlsHeight: CGFloat = 148
        switch cell {
        case temperatureAlertHeaderCell:
            return headerHeight
        case temperatureAlertControlsCell:
            return (viewModel.isTemperatureAlertOn.value ?? false) ? controlsHeight : 0
        default:
            return 44
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case WebTagSettingsSection.name.rawValue:
            return "WebTagSettings.SectionHeader.Name.title".localized()
        case WebTagSettingsSection.alerts.rawValue:
            return "WebTagSettings.SectionHeader.Alerts.title".localized()
        case WebTagSettingsSection.moreInfo.rawValue:
            return "WebTagSettings.SectionHeader.MoreInfo.title".localized()
        default:
            return nil
        }
    }
}
// MARK: - UITextFieldDelegate
extension WebTagSettingsTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return false
    }
}

// MARK: - View configuration
extension WebTagSettingsTableViewController {
    private func configureViews() {
        temperatureAlertHeaderCell.delegate = self
        temperatureAlertControlsCell.delegate = self
    }
}

// MARK: - Update UI
extension WebTagSettingsTableViewController {
    private func updateUI() {
        updateUIIsNamaChangeEnabled()
    }

    private func updateUIIsNamaChangeEnabled() {
        if isViewLoaded {
            tagNameTextField.isEnabled = isNameChangedEnabled
        }
    }

    private func updateUITemperatureAlertDescription() {
        if isViewLoaded {
            if let isTemperatureAlertOn = viewModel.isTemperatureAlertOn.value, isTemperatureAlertOn {
                if let l = viewModel.celsiusLowerBound.value,
                    let u = viewModel.celsiusUpperBound.value,
                    let tu = viewModel.temperatureUnit.value {
                    var la: Double
                    var ua: Double
                    switch tu {
                    case .celsius:
                        la = l
                        ua = u
                    case .fahrenheit:
                        la = l.fahrenheit
                        ua = u.fahrenheit
                    case .kelvin:
                        la = l.kelvin
                        ua = u.kelvin
                    }
                    let format = "WebTagSettings.Alerts.Temperature.description".localized()
                    temperatureAlertHeaderCell.descriptionLabel.text = String(format: format, la, ua)
                } else {
                    temperatureAlertHeaderCell.descriptionLabel.text = "WebTagSettings.Alerts.Off".localized()
                }
            } else {
                temperatureAlertHeaderCell.descriptionLabel.text = "WebTagSettings.Alerts.Off".localized()
            }
        }
    }

    private func updateUICelsiusLowerBound() {
        if isViewLoaded {
            if let temperatureUnit = viewModel.temperatureUnit.value {
                if let lower = viewModel.celsiusLowerBound.value {
                    switch temperatureUnit {
                    case .celsius:
                        temperatureAlertControlsCell.slider.selectedMinValue = CGFloat(lower)
                    case .fahrenheit:
                        temperatureAlertControlsCell.slider.selectedMinValue = CGFloat(lower.fahrenheit)
                    case .kelvin:
                        temperatureAlertControlsCell.slider.selectedMinValue = CGFloat(lower.kelvin)
                    }
                } else {
                    temperatureAlertControlsCell.slider.selectedMinValue = -40
                }
            } else {
                temperatureAlertControlsCell.slider.minValue = -40
                temperatureAlertControlsCell.slider.selectedMinValue = -40
            }
        }
    }

    private func updateUICelsiusUpperBound() {
        if isViewLoaded {
            if let temperatureUnit = viewModel.temperatureUnit.value {
                if let upper = viewModel.celsiusUpperBound.value {
                    switch temperatureUnit {
                    case .celsius:
                        temperatureAlertControlsCell.slider.selectedMaxValue = CGFloat(upper)
                    case .fahrenheit:
                        temperatureAlertControlsCell.slider.selectedMaxValue = CGFloat(upper.fahrenheit)
                    case .kelvin:
                        temperatureAlertControlsCell.slider.selectedMaxValue = CGFloat(upper.kelvin)
                    }
                } else {
                    temperatureAlertControlsCell.slider.selectedMaxValue = 85
                }
            } else {
                temperatureAlertControlsCell.slider.maxValue = 85
                temperatureAlertControlsCell.slider.selectedMaxValue = 85
            }
        }
    }
}

// MARK: - WebTagSettingsAlertHeaderCellDelegate
extension WebTagSettingsTableViewController: WebTagSettingsAlertHeaderCellDelegate {
    func webTagSettingsAlertHeader(cell: WebTagSettingsAlertHeaderCell, didToggle isOn: Bool) {
        switch cell {
        case temperatureAlertHeaderCell:
            viewModel.isTemperatureAlertOn.value = isOn
        default:
            break
        }
    }
}

// MARK: - WebTagSettingsAlertControlsCellDelegate
extension WebTagSettingsTableViewController: WebTagSettingsAlertControlsCellDelegate {
    func webTagSettingsAlertControls(cell: WebTagSettingsAlertControlsCell, didEnter description: String?) {
        switch cell {
        case temperatureAlertControlsCell:
            viewModel.temperatureAlertDescription.value = description
        default:
            break
        }
    }

    func webTagSettingsAlertControls(cell: WebTagSettingsAlertControlsCell, didSlideTo minValue: CGFloat, maxValue: CGFloat) {
        switch cell {
        case temperatureAlertControlsCell:
            if let tu = viewModel.temperatureUnit.value {
                switch tu {
                case .celsius:
                    viewModel.celsiusLowerBound.value = Double(minValue)
                    viewModel.celsiusUpperBound.value = Double(maxValue)
                case .fahrenheit:
                    viewModel.celsiusLowerBound.value = Double(minValue).celsiusFromFahrenheit
                    viewModel.celsiusUpperBound.value = Double(maxValue).celsiusFromFahrenheit
                case .kelvin:
                    viewModel.celsiusLowerBound.value = Double(minValue).celsiusFromKelvin
                    viewModel.celsiusUpperBound.value = Double(maxValue).celsiusFromKelvin
                }
            }
        default:
            break
        }
    }
}

// MARK: - Bindings
extension WebTagSettingsTableViewController {

    private func bindViewModel() {
        backgroundImageView.bind(viewModel.background) { $0.image = $1 }
        tagNameTextField.bind(viewModel.name) { $0.text = $1 }
        let clearButton = clearLocationButton
        let clearWidth = clearLocationButtonWidth
        locationValueLabel.bind(viewModel.location, block: { [weak clearButton, weak clearWidth] label, location in
            label.text = location?.cityCommaCountry ?? "WebTagSettings.Location.Current".localized()
            clearButton?.isHidden = location == nil
            clearWidth?.constant = location == nil ? 0 : 36
        })
        bindTemperatureAlertCells()
    }

    // swiftlint:disable:next function_body_length
    private func bindTemperatureAlertCells() {
        if isViewLoaded {

            temperatureAlertControlsCell.slider.bind(viewModel.temperatureUnit) { (slider, temperatureUnit) in
                if let tu = temperatureUnit {
                    switch tu {
                    case .celsius:
                        slider.minValue = -40
                        slider.maxValue = 85
                    case .fahrenheit:
                        slider.minValue = -40
                        slider.maxValue = 185
                    case .kelvin:
                        slider.minValue = 233
                        slider.maxValue = 358
                    }
                }
            }
            temperatureAlertHeaderCell.isOnSwitch.bind(viewModel.isTemperatureAlertOn) { (view, isOn) in
                view.isOn = isOn.bound
            }
            temperatureAlertControlsCell.slider.bind(viewModel.isTemperatureAlertOn) { (slider, isOn) in
                slider.isEnabled = isOn.bound
            }

            temperatureAlertControlsCell.slider.bind(viewModel.celsiusLowerBound) { [weak self] (_, _) in
                self?.updateUICelsiusLowerBound()
                self?.updateUITemperatureAlertDescription()
            }
            temperatureAlertControlsCell.slider.bind(viewModel.celsiusUpperBound) { [weak self] (_, _) in
                self?.updateUICelsiusUpperBound()
                self?.updateUITemperatureAlertDescription()
            }

            temperatureAlertHeaderCell.titleLabel.bind(viewModel.temperatureUnit) { (label, temperatureUnit) in
                if let tu = temperatureUnit {
                    switch tu {
                    case .celsius:
                        label.text = "WebTagSettings.temperatureAlertTitleLabel.text".localized() + " " + "°C".localized()
                    case .fahrenheit:
                        label.text = "WebTagSettings.temperatureAlertTitleLabel.text".localized() + " " + "°F".localized()
                    case .kelvin:
                        label.text = "WebTagSettings.temperatureAlertTitleLabel.text".localized() + " "  + "K".localized()
                    }
                } else {
                    label.text = "N/A".localized()
                }
            }
            temperatureAlertHeaderCell.descriptionLabel.bind(viewModel.isTemperatureAlertOn) { [weak self] (_, _) in
                self?.updateUITemperatureAlertDescription()
            }

            let isTemperatureAlertOn = viewModel.isTemperatureAlertOn
            temperatureAlertHeaderCell.isOnSwitch.bind(viewModel.isPushNotificationsEnabled) {
                view, isPushNotificationsEnabled in
                let isPN = isPushNotificationsEnabled ?? false
                let isEnabled = isPN
                view.isEnabled = isEnabled
                view.onTintColor = isEnabled ? UISwitch.appearance().onTintColor : .gray
            }
            temperatureAlertControlsCell.slider.bind(viewModel.isPushNotificationsEnabled) {
                [weak isTemperatureAlertOn] (slider, isPushNotificationsEnabled) in
                let isOn = isTemperatureAlertOn?.value ?? false
                slider.isEnabled = isPushNotificationsEnabled.bound && isOn
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
    }
}
// swiftlint:enable file_length
