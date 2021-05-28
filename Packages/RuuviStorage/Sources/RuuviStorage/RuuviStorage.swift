import Foundation
import Future
import RuuviOntology
import RuuviPersistence

public protocol RuuviStorage {
    func read(
        _ id: String,
        after date: Date,
        with interval: TimeInterval
    ) -> Future<[RuuviTagSensorRecord], RuuviStorageError>
    func readOne(_ id: String) -> Future<AnyRuuviTagSensor, RuuviStorageError>
    func readAll(_ id: String) -> Future<[RuuviTagSensorRecord], RuuviStorageError>
    func readAll(_ id: String, with interval: TimeInterval) -> Future<[RuuviTagSensorRecord], RuuviStorageError>
    func readAll() -> Future<[AnyRuuviTagSensor], RuuviStorageError>
    func readLast(_ id: String, from: TimeInterval) -> Future<[RuuviTagSensorRecord], RuuviStorageError>
    func readLast(_ ruuviTag: RuuviTagSensor) -> Future<RuuviTagSensorRecord?, RuuviStorageError>
    func getStoredTagsCount() -> Future<Int, RuuviStorageError>
    func getStoredMeasurementsCount() -> Future<Int, RuuviStorageError>
    func readSensorSettings(_ ruuviTag: RuuviTagSensor) -> Future<SensorSettings?, RuuviStorageError>
    func updateOffsetCorrection(
        type: OffsetCorrectionType,
        with value: Double?,
        of ruuviTag: RuuviTagSensor,
        lastOriginalRecord record: RuuviTagSensorRecord?
    ) -> Future<SensorSettings, RuuviStorageError>
}

public protocol RuuviStorageFactory {
    func create(realm: RuuviPersistence, sqlite: RuuviPersistence) -> RuuviStorage
}
