import SwiftUI
import Humidity
import RuuviOntology

// MARK: - COLORS
// Necessary colors used on the widgets
extension Color {
    static let logoColor = Color("LogoColor")
    static let backgroundColor = Color("BackgroundColor")
    static let bodyTextColor = Color("BodyTextColor")
    static let sensorNameColor1 = Color("SensorNameColor1")
    static let sensorNameColor2 = Color("SensorNameColor2")
    static let unitTextColor = Color("UnitTextColor")
}

// MARK: - LANGUAGE
extension Language {
    public var locale: Locale {
        switch self {
        case .english:
            return Locale(identifier: "en_US")
        case .russian:
            return Locale(identifier: "ru_RU")
        case .finnish:
            return Locale(identifier: "fi")
        case .french:
            return Locale(identifier: "fr")
        case .swedish:
            return Locale(identifier: "sv")
        case .german:
            return Locale(identifier: "de")
        }
    }

    public var humidityLanguage: HumiditySettings.Language {
        switch self {
        case .german:
            return .en
        case .russian:
            return .ru
        case .finnish:
            return .fi
        case .french:
            return .en
        case .swedish:
            return .sv
        case .english:
            return .en
        }
    }
}

// MARK: - HUMIDITY

extension HumidityUnit {
    var symbol: String {
        switch self {
        case .percent:
            return "%"
        case .gm3:
            return "g/m³"
        default:
            return "°"
        }
    }
}

// MARK: - NUMBERS
extension Double {
    func round(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        let rounded = (self * divisor).rounded(.toNearestOrAwayFromZero) / divisor
        return rounded
    }

    var clean: String {
        return self.truncatingRemainder(dividingBy: 1) == 0 ? String(format: "%.0f", self) : String(self)
    }

    var value: String {
        return String(self)
    }

    var nsNumber: NSNumber {
        return NSNumber(value: self)
    }
}

extension Int {
    var value: String {
        return String(self)
    }

    var double: Double {
        return Double(self)
    }
}
// MARK: - String
extension Optional where Wrapped == String {
    var unwrapped: String {
        return self ?? ""
    }
}

extension String {
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
}

extension String {

    var length: Int {
        return count
    }

    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }

    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }

    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }

    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = index(startIndex, offsetBy: range.lowerBound)
        let end = index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self[start ..< end])
    }
}
