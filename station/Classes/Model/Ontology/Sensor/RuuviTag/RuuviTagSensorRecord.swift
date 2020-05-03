import Foundation
import Humidity

protocol RuuviTagSensorRecord {
    var ruuviTagId: String { get }
    var date: Date { get }
    var mac: String? { get }
    var rssi: Int? { get }
    var temperature: Temperature? { get }
    var humidity: Humidity? { get }
    var pressure: Pressure? { get }
    // v3 & v5
    var acceleration: Acceleration? { get }
    var voltage: Voltage? { get }
    // v5
    var movementCounter: Int? { get }
    var measurementSequenceNumber: Int? { get }
    var txPower: Int? { get }
}

extension RuuviTagSensorRecord {
    var id: String {
        return ruuviTagId + "\(date.timeIntervalSince1970)"
    }

    var any: AnyRuuviTagSensorRecord {
        return AnyRuuviTagSensorRecord(object: self)
    }

    func with(mac: String) -> RuuviTagSensorRecord {
        return RuuviTagSensorRecordStruct(ruuviTagId: mac,
                                          date: date,
                                          mac: mac,
                                          rssi: rssi,
                                          temperature: temperature,
                                          humidity: humidity,
                                          pressure: pressure,
                                          acceleration: acceleration,
                                          voltage: voltage,
                                          movementCounter: movementCounter,
                                          measurementSequenceNumber: measurementSequenceNumber,
                                          txPower: txPower)
    }
}

struct RuuviTagSensorRecordStruct: RuuviTagSensorRecord {
    var ruuviTagId: String
    var date: Date
    var mac: String?
    var rssi: Int?
    var temperature: Temperature?
    var humidity: Humidity?
    var pressure: Pressure?
    // v3 & v5
    var acceleration: Acceleration?
    var voltage: Voltage?
    // v5
    var movementCounter: Int?
    var measurementSequenceNumber: Int?
    var txPower: Int?
}

struct AnyRuuviTagSensorRecord: RuuviTagSensorRecord, Equatable, Hashable {
    var object: RuuviTagSensorRecord

    var ruuviTagId: String {
        return object.ruuviTagId
    }

    var date: Date {
        return object.date
    }

    var mac: String? {
        return object.mac
    }

    var rssi: Int? {
        return object.rssi
    }

    var temperature: Temperature? {
        return object.temperature
    }

    var humidity: Humidity? {
        return object.humidity
    }

    var pressure: Pressure? {
        return object.pressure
    }

    var acceleration: Acceleration? {
        return object.acceleration
    }

    var voltage: Voltage? {
        return object.voltage
    }

    var movementCounter: Int? {
        return object.movementCounter
    }

    var measurementSequenceNumber: Int? {
        return object.measurementSequenceNumber
    }

    var txPower: Int? {
        return object.txPower
    }

    static func == (lhs: AnyRuuviTagSensorRecord, rhs: AnyRuuviTagSensorRecord) -> Bool {
        return lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
