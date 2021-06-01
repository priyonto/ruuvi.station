import UIKit

protocol TagSettingsViewOutput {
    func viewDidLoad()
    func viewWillAppear()
    func viewDidAskToDismiss()
    func viewDidAskToRandomizeBackground()
    func viewDidAskToRemoveRuuviTag()
    func viewDidConfirmTagRemoval()
    func viewDidChangeTag(name: String)
    func viewDidAskToSelectBackground(sourceView: UIView)
    func viewDidTapOnMacAddress()
    func viewDidTapOnUUID()
    func viewDidAskToLearnMoreAboutFirmwareUpdate()
    func viewDidTapOnTxPower()
    func viewDidTapOnMeasurementSequenceNumber()
    func viewDidTapOnNoValuesView()
    func viewDidTapOnHumidityAccessoryButton()
    func viewDidAskToFixHumidityAdjustment()
    func viewDidTapOnAlertsDisabledView()
    func viewDidAskToConnectFromAlertsDisabledDialog()
    func viewDidTapClaimButton()
    func viewDidTapShareButton()
    func viewDidTapOnBackgroundIndicator()

    // Offset Correction
    func viewDidTapTemperatureOffsetCorrection()
    func viewDidTapHumidityOffsetCorrection()
    func viewDidTapOnPressureOffsetCorrection()
}
