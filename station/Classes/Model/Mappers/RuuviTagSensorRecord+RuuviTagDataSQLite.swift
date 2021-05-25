import Foundation

extension RuuviTagSensorRecord {
    var sqlite: RuuviTagDataSQLite {
        return RuuviTagDataSQLite(ruuviTagId: ruuviTagId,
                                  date: date,
                                  source: source,
                                  macId: macId,
                                  rssi: rssi,
                                  temperature: temperature,
                                  humidity: humidity,
                                  pressure: pressure,
                                  acceleration: acceleration,
                                  voltage: voltage,
                                  movementCounter: movementCounter,
                                  measurementSequenceNumber: measurementSequenceNumber,
                                  txPower: txPower,
                                  temperatureOffset: temperatureOffset,
                                  humidityOffset: humidityOffset,
                                  pressureOffset: pressureOffset)
    }
}
