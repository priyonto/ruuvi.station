import Foundation
import Humidity
import RealmSwift
import RuuviOntology

extension RuuviTagDataRealm {
    public var unitTemperature: Temperature? {
        guard let celsius = self.celsius.value else {
            return nil
        }
        return Temperature(value: celsius,
                           unit: .celsius)
    }
    public var unitHumidity: Humidity? {
        guard let celsius = self.celsius.value,
            let relativeHumidity = self.humidity.value else {
            return nil
        }
        return Humidity(relative: relativeHumidity,
                        temperature: Temperature(value: celsius, unit: .celsius))
    }
    public var unitPressure: Pressure? {
        guard let pressure = self.pressure.value else {
            return nil
        }
        return Pressure(value: pressure,
                        unit: .hectopascals)
    }
    public var acceleration: Acceleration? {
        guard let accelerationX = self.accelerationX.value,
            let accelerationY = self.accelerationY.value,
            let accelerationZ = self.accelerationZ.value else {
            return nil
        }
        return Acceleration(x:
            AccelerationMeasurement(value: accelerationX,
                                    unit: .metersPerSecondSquared),
                            y:
            AccelerationMeasurement(value: accelerationY,
                                    unit: .metersPerSecondSquared),
                            z:
            AccelerationMeasurement(value: accelerationZ,
                                    unit: .metersPerSecondSquared)
        )
    }
    public var unitVoltage: Voltage? {
        guard let voltage = self.voltage.value else { return nil }
        return Voltage(value: voltage, unit: .volts)
    }
    public var measurement: RuuviMeasurement {
        return RuuviMeasurement(
            luid: ruuviTag?.luid,
            macId: ruuviTag?.macId,
            measurementSequenceNumber: measurementSequenceNumber.value,
            date: date,
            rssi: rssi.value,
            temperature: unitTemperature,
            humidity: unitHumidity,
            pressure: unitPressure,
            acceleration: acceleration,
            voltage: unitVoltage,
            movementCounter: movementCounter.value,
            txPower: txPower.value,
            temperatureOffset: temperatureOffset,
            humidityOffset: humidityOffset,
            pressureOffset: pressureOffset
        )
    }
}
