import Foundation
import RuuviOntology

public enum RuuviCloudApiSetting: String, CaseIterable, Codable {
    case unitTemperature = "UNIT_TEMPERATURE"
    case unitHumidity = "UNIT_HUMIDITY"
    case unitPressure = "UNIT_PRESSURE"
}

extension TemperatureUnit {
    var ruuviCloudApiSettingString: String {
        switch self {
        case .celsius:
            return "C"
        case .fahrenheit:
            return "F"
        case .kelvin:
            return "K"
        }
    }
}

extension HumidityUnit {
    var ruuviCloudApiSettingString: String {
        switch self {
        case .percent:
            return "0"
        case .gm3:
            return "1"
        case .dew:
            return "2"
        }
    }
}

extension UnitPressure {
    var ruuviCloudApiSettingString: String {
        switch self {
        case .hectopascals:
            return "1"
        case .millimetersOfMercury:
            return "2"
        case .inchesOfMercury:
            return "3"
        default:
            assertionFailure()
            return ""
        }
    }
}

extension String {
    var ruuviCloudApiSettingUnitTemperature: TemperatureUnit? {
        switch self {
        case "C":
            return .celsius
        case "F":
            return .fahrenheit
        case "K":
            return .kelvin
        default:
            return nil
        }
    }

    var ruuviCloudApiSettingUnitHumidity: HumidityUnit? {
        switch self {
        case "0":
            return .percent
        case "1":
            return .gm3
        case "2":
            return .dew
        default:
            return nil
        }
    }

    var ruuviCloudApiSettingUnitPressure: UnitPressure? {
        switch self {
        case "0":
            return nil // TODO: @rinat support Pa
        case "1":
            return .hectopascals
        case "2":
            return .millimetersOfMercury
        case "3":
            return .inchesOfMercury
        default:
            return nil
        }
    }
}
