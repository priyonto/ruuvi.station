import Foundation
import RuuviOntology
import RuuviLocal
import RuuviService

class UnitSettingsPresenter {
    weak var view: UnitSettingsViewInput!
    var router: UnitSettingsRouterInput!
    var settings: RuuviLocalSettings!
    var ruuviAppSettingsService: RuuviServiceAppSettings!

    private var viewModel: UnitSettingsViewModel? {
        didSet {
            view.viewModel = viewModel
        }
    }
    var output: UnitSettingsModuleOutput?
}
extension UnitSettingsPresenter: UnitSettingsModuleInput {
    func configure(viewModel: UnitSettingsViewModel, output: UnitSettingsModuleOutput?) {
        self.viewModel = viewModel
        self.output = output
    }

    func dismiss() {
        router.dismiss()
    }
}

extension UnitSettingsPresenter: UnitSettingsViewOutput {
    func viewDidLoad() {
        view.temperatureUnit = settings.temperatureUnit
        view.humidityUnit = settings.humidityUnit
        view.pressureUnit = settings.pressureUnit
        view.temperatureAccuracy = settings.temperatureAccuracy
        view.humidityAccuracy = settings.humidityAccuracy
        view.pressureAccuracy = settings.pressureAccuracy
    }

    func viewDidSelect(type: UnitSettingsType) {
        switch type {
        case .unit:
            guard let viewModel = unitViewModel() else {
                return
            }
            router.openSelection(with: viewModel, output: self)

        case .accuracy:
            guard let viewModel = accuracyViewModel() else {
                return
            }
            router.openSelection(with: viewModel, output: self)
        }
    }
}

extension UnitSettingsPresenter: SelectionModuleOutput {
    // swiftlint:disable:next cyclomatic_complexity
    func selection(module: SelectionModuleInput, didSelectItem item: SelectionItemProtocol, type: UnitSettingsType) {
        switch type {
        case .unit:
            switch item {
            case let temperatureUnit as TemperatureUnit:
                ruuviAppSettingsService.set(temperatureUnit: temperatureUnit)
                view.temperatureUnit = temperatureUnit
            case let humidityUnit as HumidityUnit:
                ruuviAppSettingsService.set(humidityUnit: humidityUnit)
                view.humidityUnit = humidityUnit
            case let pressureUnit as UnitPressure:
                ruuviAppSettingsService.set(pressureUnit: pressureUnit)
                view.pressureUnit = pressureUnit
            default:
                break
            }
        case .accuracy:
            guard let viewModel = viewModel,
                    let item = item as? MeasurementAccuracyType else {
                return
            }
            switch viewModel.measurementType {
            case .temperature:
                ruuviAppSettingsService.set(temperatureAccuracy: item)
                view.temperatureAccuracy = item
            case .humidity:
                ruuviAppSettingsService.set(humidityAccuracy: item)
                view.humidityAccuracy = item
            case .pressure:
                ruuviAppSettingsService.set(pressureAccuracy: item)
                view.pressureAccuracy = item
            default:
                return
            }
        }
        module.dismiss()
    }
}

extension UnitSettingsPresenter {
    private func unitViewModel() -> SelectionViewModel? {
        guard let viewModel = viewModel else {
            return nil
        }

        switch viewModel.measurementType {
        case .temperature:
            return SelectionViewModel(title: "Settings.Label.TemperatureUnit.text".localized(),
                                      items: viewModel.items,
                                      description: "Settings.ChooseTemperatureUnit.text".localized(),
                                      selection: settings.temperatureUnit.title,
                                      measurementType: viewModel.measurementType,
                                      unitSettingsType: .unit)

        case .humidity:
            return SelectionViewModel(title: "Settings.Label.HumidityUnit.text".localized(),
                                      items: viewModel.items,
                                      description: "Settings.ChooseHumidityUnit.text".localized(),
                                      selection: settings.humidityUnit.title,
                                      measurementType: viewModel.measurementType,
                                      unitSettingsType: .unit)

        case .pressure:
            return SelectionViewModel(title: "Settings.Label.PressureUnit.text".localized(),
                                      items: viewModel.items,
                                      description: "Settings.ChooseOressureUnit.text".localized(),
                                      selection: settings.pressureUnit.title,
                                      measurementType: viewModel.measurementType,
                                      unitSettingsType: .unit)

        default:
            return nil
        }
    }

    private func accuracyViewModel() -> SelectionViewModel? {
        var accuracyTitle: String
        var selection: String
        guard let measurementType = viewModel?.measurementType else {
            return nil
        }
        let titleProvider = MeasurementAccuracyTitles()
        switch measurementType {
        case .temperature:
            accuracyTitle = "Settings.Temperature.Resolution.title".localized()
            selection = titleProvider.formattedTitle(type: settings.temperatureAccuracy, settings: settings)
        case .humidity:
            accuracyTitle = "Settings.Humidity.Resolution.title".localized()
            selection = titleProvider.formattedTitle(type: settings.humidityAccuracy, settings: settings)
        case .pressure:
            accuracyTitle = "Settings.Pressure.Resolution.title".localized()
            selection = titleProvider.formattedTitle(type: settings.pressureAccuracy, settings: settings)
        default:
            return nil
        }

        let selectionItems: [MeasurementAccuracyType] = [
            .zero,
            .one,
            .two
        ]

        return SelectionViewModel(title: accuracyTitle,
                                  items: selectionItems,
                                  description: "Settings.Measurement.Resolution.description".localized(),
                                  selection: selection,
                                  measurementType: measurementType,
                                  unitSettingsType: .accuracy)
    }
}
