import BTKit
import Humidity

extension RuuviTagEnvLogFull {

    var unitTemperature: Temperature? {
        return Temperature(value: temperature, unit: .celsius)
    }
    var unitHumidity: Humidity? {
        return Humidity(relative: humidity, temperature: unitTemperature)
    }
    var unitPressure: Pressure? {
        return Pressure(value: pressure, unit: .hectopascals)
    }
    var acceleration: Acceleration? {
        return nil
    }
    var unitVoltage: Voltage? {
        return nil
    }

    func ruuviSensorRecord(uuid: String, mac: String?) -> RuuviTagSensorRecord {
        return RuuviTagSensorRecordStruct(
            ruuviTagId: mac ?? uuid,
            date: date,
            source: .log,
            macId: mac?.mac,
            rssi: nil,
            temperature: unitTemperature,
            humidity: unitHumidity,
            pressure: unitPressure,
            acceleration: acceleration,
            voltage: unitVoltage,
            movementCounter: nil,
            measurementSequenceNumber: nil,
            txPower: nil,
            temperatureOffset: 0.0,
            humidityOffset: 0.0,
            pressureOffset: 0.0
        )
    }
}
