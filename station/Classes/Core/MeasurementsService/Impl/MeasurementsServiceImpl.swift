import Foundation
import Humidity
import RuuviOntology

struct MeasurementsServiceSettigsUnit {
    let temperatureUnit: UnitTemperature
    let humidityUnit: HumidityUnit
    let pressureUnit: UnitPressure
}

class MeasurementsServiceImpl: NSObject {
    var settings: Settings! {
        didSet {
            units = MeasurementsServiceSettigsUnit(temperatureUnit: settings.temperatureUnit.unitTemperature,
                                                   humidityUnit: settings.humidityUnit,
                                                   pressureUnit: settings.pressureUnit)
        }
    }
    var units: MeasurementsServiceSettigsUnit! {
        didSet {
            notifyListeners()
        }
    }

    private let notificationsNamesToObserve: [Notification.Name] = [
        .TemperatureUnitDidChange,
        .HumidityUnitDidChange,
        .PressureUnitDidChange
    ]

    private var observers: [NSObjectProtocol] = []

    private var numberFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = settings.language.locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        return formatter
    }

    private var formatter: MeasurementFormatter {
        let measurementFormatter = MeasurementFormatter()
        measurementFormatter.locale = settings.language.locale
        measurementFormatter.unitOptions = .providedUnit
        measurementFormatter.numberFormatter = self.numberFormatter
        return measurementFormatter
    }

    private var humidityFormatter: HumidityFormatter {
        let humidityFormatter = HumidityFormatter()
        humidityFormatter.numberFormatter = self.numberFormatter
        HumiditySettings.setLanguage(self.settings.language.humidityLanguage)
        return humidityFormatter
    }

    private var listeners = NSHashTable<AnyObject>.weakObjects()

    override init() {
        super.init()
        startSettingsObserving()
    }

    func add(_ listener: MeasurementsServiceDelegate) {
        guard !listeners.contains(listener) else { return }
        listeners.add(listener)
    }
}
// MARK: - MeasurementsService
extension MeasurementsServiceImpl: MeasurementsService {

    func double(for temperature: Temperature) -> Double {
        return temperature
            .converted(to: units.temperatureUnit)
            .value
            .round(to: numberFormatter.maximumFractionDigits)
    }

    func string(for temperature: Temperature?) -> String {
        guard let temperature = temperature else {
            return "N/A".localized()
        }
        let value = temperature.converted(to: units.temperatureUnit).value
        let number = NSNumber(value: value)
        numberFormatter.numberStyle = .decimal
        if formatter.unitStyle == .medium,
           settings.language == .english,
           let valueString = numberFormatter.string(from: number) {
            return String(format: "%@\(String.nbsp)%@",
                          valueString,
                          units.temperatureUnit.symbol)
        } else {
            return formatter.string(from: temperature.converted(to: units.temperatureUnit))
        }
    }

    func stringWithoutSign(for temperature: Temperature?) -> String {
        guard let temperature = temperature else {
            return "N/A".localized()
        }
        let value = temperature.converted(to: units.temperatureUnit).value
        let number = NSNumber(value: value)
        numberFormatter.numberStyle = .decimal
        numberFormatter.locale = settings.language.locale
        return numberFormatter.string(from: number) ?? "N/A".localized()
    }

    func double(for pressure: Pressure) -> Double {
        let pressureValue = pressure
            .converted(to: units.pressureUnit)
            .value
        if units.pressureUnit == .inchesOfMercury {
            return pressureValue
        } else {
            return pressureValue.round(to: numberFormatter.maximumFractionDigits)
        }
    }

    func string(for pressure: Pressure?) -> String {
        guard let pressure = pressure else {
            return "N/A".localized()
        }
        return formatter.string(from: pressure.converted(to: units.pressureUnit))
    }

    func double(for voltage: Voltage) -> Double {
        return voltage
            .converted(to: .volts)
            .value
            .round(to: numberFormatter.maximumFractionDigits)
    }

    func string(for voltage: Voltage?) -> String {
        guard let voltage = voltage else {
            return "N/A".localized()
        }
        return formatter.string(from: voltage.converted(to: .volts))
    }

    func double(for humidity: Humidity,
                temperature: Temperature,
                isDecimal: Bool) -> Double? {
        let humidityWithTemperature = Humidity(
            value: humidity.value,
            unit: .relative(temperature: temperature)
        )
        switch units.humidityUnit {
        case .percent:
            let value = humidityWithTemperature.value
            return isDecimal
                ? value
                    .round(to: numberFormatter.maximumFractionDigits)
                : (value * 100)
                    .round(to: numberFormatter.maximumFractionDigits)
        case .gm3:
            return humidity.converted(to: .absolute)
                .value
                .round(to: numberFormatter.maximumFractionDigits)
        case .dew:
            let dp = try? humidity.dewPoint(temperature: temperature)
            return dp?.converted(to: settings.temperatureUnit.unitTemperature)
                .value
                .round(to: numberFormatter.maximumFractionDigits)
        }
    }

    func string(for humidity: Humidity?,
                temperature: Temperature?) -> String {
        guard let humidity = humidity,
            let temperature = temperature else {
                return "N/A".localized()
        }

        let humidityWithTemperature = Humidity(
            value: humidity.value,
            unit: .relative(temperature: temperature)
        )
        switch units.humidityUnit {
        case .percent:
            return humidityFormatter.string(from: humidityWithTemperature)
        case .gm3:
            return humidityFormatter.string(from: humidityWithTemperature.converted(to: .absolute))
        case .dew:
            let dp = try? humidityWithTemperature.dewPoint(temperature: temperature)
            return string(for: dp)
        }
    }
}
// MARK: - Private
extension MeasurementsServiceImpl {
    private func notifyListeners() {
        listeners
            .allObjects
            .compactMap({
                $0 as? MeasurementsServiceDelegate
            }).forEach({
                $0.measurementServiceDidUpdateUnit()
            })
    }

    private func updateCache() {
        updateUnits()
        notifyListeners()
    }

    func updateUnits() {
        units = MeasurementsServiceSettigsUnit(temperatureUnit: settings.temperatureUnit.unitTemperature,
                                               humidityUnit: settings.humidityUnit,
                                               pressureUnit: settings.pressureUnit)
    }

    private func startSettingsObserving() {
        notificationsNamesToObserve.forEach({
            let observer = NotificationCenter
                .default
                .addObserver(forName: $0,
                             object: nil,
                             queue: .main) { [weak self] (_) in
                self?.updateCache()
            }
            self.observers.append(observer)
        })
    }
}

extension MeasurementsServiceImpl {
    func temperatureOffsetCorrection(for temperature: Double) -> Double {
        switch units.temperatureUnit {
        case .fahrenheit:
            return temperature * 1.8
        default:
            return temperature
        }
    }

    func temperatureOffsetCorrectionString(for temperature: Double) -> String {
        return string(for: Temperature(
            temperatureOffsetCorrection(for: temperature),
            unit: units.temperatureUnit
        ))
    }

    func humidityOffsetCorrection(for humidity: Double) -> Double {
        return humidity
    }

    func humidityOffsetCorrectionString(for humidity: Double) -> String {
        return "\((humidityOffsetCorrection(for: humidity) * 100).round(to: 2)) \("%".localized())"
    }

    func pressureOffsetCorrection(for pressure: Double) -> Double {
        return double(for: Pressure.init(value: pressure, unit: .hectopascals))
    }

    func pressureOffsetCorrectionString(for pressure: Double) -> String {
        return string(for: Pressure(
            pressureOffsetCorrection(for: pressure),
            unit: units.pressureUnit
        ))
    }
}
