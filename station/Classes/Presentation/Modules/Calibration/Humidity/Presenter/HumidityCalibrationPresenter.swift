import Foundation
import BTKit

class HumidityCalibrationPresenter: HumidityCalibrationModuleInput {
    weak var view: HumidityCalibrationViewInput!
    var router: HumidityCalibrationRouterInput!
    var calibrationService: CalibrationService!
    var errorPresenter: ErrorPresenter!
    var foreground: BTForeground!
    var background: BTBackground!

    private var ruuviTag: RuuviTagSensor!
    private var humidity: Double!
    private var advertisementToken: ObservationToken?
    private var heartbeatToken: ObservationToken?

    deinit {
        advertisementToken?.invalidate()
        heartbeatToken?.invalidate()
    }

    func configure(ruuviTag: RuuviTagSensor, humidity: Double) {
        self.ruuviTag = ruuviTag
        self.humidity = humidity
        updateView()
    }
}

extension HumidityCalibrationPresenter: HumidityCalibrationViewOutput {
    func viewDidLoad() {
        startScanningHumidity()
    }

    func viewDidTapOnDimmingView() {
        router.dismiss()
    }

    func viewDidTriggerClose() {
        router.dismiss()
    }

    func viewDidTriggerClearCalibration() {
        view.showClearCalibrationConfirmationDialog()
    }

    func viewDidConfirmToClearHumidityOffset() {
        calibrationService.cleanHumidityCalibration(for: ruuviTag)
        updateView()
    }

    func viewDidConfirmToCalibrateHumidityOffset() {
        calibrationService.calibrateHumiditySaltTest(currentValue: humidity, for: ruuviTag)
        updateView()
    }

    func viewDidTriggerCalibrate() {
        view.showCalibrationConfirmationDialog()
    }
}

// MARK: - Scanning
extension HumidityCalibrationPresenter {
    private func startScanningHumidity() {
        advertisementToken?.invalidate()
        guard let uuid = ruuviTag.luid else { return }
        advertisementToken = foreground.observe(self, uuid: uuid) { [weak self] (_, device) in
            if let tag = device.ruuvi?.tag {
                self?.humidity = tag.relativeHumidity
                self?.updateView()
            }
        }
        heartbeatToken?.invalidate()
        heartbeatToken = background.observe(self, uuid: uuid) { [weak self] (_, device) in
            if let tag = device.ruuvi?.tag {
                self?.humidity = tag.relativeHumidity
                self?.updateView()
            }
        }
    }
}

// MARK: - Private
extension HumidityCalibrationPresenter {
    func updateView() {
        view.oldHumidity = humidity
        view.humidityOffset = calibrationService.humidityOffset(for: ruuviTag.id).0
        view.lastCalibrationDate = calibrationService.humidityOffset(for: ruuviTag.id).1
    }
}
