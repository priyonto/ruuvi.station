import BTKit
import Foundation
import Future
import GRDB
#if canImport(FirebaseCrashlytics)
import FirebaseCrashlytics
#endif

// swiftlint:disable:next type_body_length
class RuuviTagPersistenceSQLite: RuuviTagPersistence, DatabaseService {
    typealias Entity = RuuviTagSQLite
    typealias Record = RuuviTagDataSQLite
    typealias Settings = SensorSettingsSQLite
    
    let database: GRDBDatabase
    private let readQueue: DispatchQueue = DispatchQueue(label: "RuuviTagPersistenceSQLite.readQueue")
    init(database: GRDBDatabase) {
        self.database = database
    }
    
    func create(_ ruuviTag: RuuviTagSensor) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        assert(ruuviTag.macId != nil)
        let entity = Entity(id: ruuviTag.id,
                            macId: ruuviTag.macId,
                            luid: ruuviTag.luid,
                            name: ruuviTag.name,
                            version: ruuviTag.version,
                            isConnectable: ruuviTag.isConnectable)
        
        do {
            try database.dbPool.write { db in
                try entity.insert(db)
            }
            promise.succeed(value: true)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func create(_ record: RuuviTagSensorRecord) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        assert(record.macId != nil)
        do {
            var sqliteSensorSettings: Settings?
            try self.database.dbPool.read { db in
                let request = Settings.filter(Settings.tagIdColumn == record.ruuviTagId)
                sqliteSensorSettings = try request.fetchOne(db)
            }
            try database.dbPool.write { db in
                try record.with(sensorSettings: sqliteSensorSettings?.sensorSettings)
                    .sqlite.insert(db)
            }
            promise.succeed(value: true)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func create(_ records: [RuuviTagSensorRecord]) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        do {
            var sqliteSensorSettings: Settings?
            if let record = records.first {
                try self.database.dbPool.read { db in
                    let request = Settings.filter(Settings.tagIdColumn == record.ruuviTagId)
                    sqliteSensorSettings = try request.fetchOne(db)
                }
            }
            try database.dbPool.write { db in
                for record in records {
                    assert(record.macId != nil)
                    try record.with(sensorSettings: sqliteSensorSettings?.sensorSettings)
                        .sqlite.insert(db)
                }
            }
            promise.succeed(value: true)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func readAll() -> Future<[AnyRuuviTagSensor], RUError> {
        let promise = Promise<[AnyRuuviTagSensor], RUError>()
        var sqliteEntities = [RuuviTagSensor]()
        readQueue.async { [weak self] in
            do {
                try self?.database.dbPool.read { db in
                    let request = Entity.order(Entity.versionColumn)
                    sqliteEntities = try request.fetchAll(db)
                }
                promise.succeed(value: sqliteEntities.map({ $0.any }))
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    
    func readOne(_ ruuviTagId: String) -> Future<AnyRuuviTagSensor, RUError> {
        let promise = Promise<AnyRuuviTagSensor, RUError>()
        readQueue.async { [weak self] in
            var entity: Entity?
            do {
                try self?.database.dbPool.read { db in
                    let request = Entity.filter(Entity.idColumn == ruuviTagId)
                    entity = try request.fetchOne(db)
                }
                if let entity = entity {
                    promise.succeed(value: entity.any)
                } else {
                    promise.fail(error: .unexpected(.failedToFindRuuviTag))
                }
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    
    func readAll(_ ruuviTagId: String) -> Future<[RuuviTagSensorRecord], RUError> {
        let promise = Promise<[RuuviTagSensorRecord], RUError>()
        readQueue.async { [weak self] in
            var sqliteEntities = [RuuviTagSensorRecord]()
            do {
                try self?.database.dbPool.read { db in
                    let request = Record.order(Record.dateColumn)
                        .filter(Record.ruuviTagIdColumn == ruuviTagId)
                    sqliteEntities = try request.fetchAll(db)
                }
                promise.succeed(value: sqliteEntities.map({ $0.any }))
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    
    func read(
        _ ruuviTagId: String,
        after date: Date,
        with interval: TimeInterval
    ) -> Future<[RuuviTagSensorRecord], RUError> {
        let promise = Promise<[RuuviTagSensorRecord], RUError>()
        readQueue.async { [weak self] in
            var sqliteEntities = [RuuviTagSensorRecord]()
            do {
                try self?.database.dbPool.read { db in
                    let request = """
                    SELECT
                        *
                    FROM  ruuvi_tag_sensor_records rtsr
                    WHERE rtsr.ruuviTagId = '\(ruuviTagId)' AND rtsr.date > ?
                    GROUP BY STRFTIME('%s', STRFTIME('%Y-%m-%d %H:%M:%S', rtsr.date) ) / \(Int(interval))
                    ORDER BY date
                    """
                    sqliteEntities = try Record.fetchAll(
                        db,
                        sql: request,
                        arguments: [date]
                    )
                }
                promise.succeed(value: sqliteEntities.map({ $0.any }))
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    
    func readAll(_ ruuviTagId: String, with interval: TimeInterval) -> Future<[RuuviTagSensorRecord], RUError> {
        let promise = Promise<[RuuviTagSensorRecord], RUError>()
        readQueue.async { [weak self] in
            var sqliteEntities = [RuuviTagSensorRecord]()
            do {
                try self?.database.dbPool.read { db in
                    let request = """
                    SELECT
                        *
                    FROM  ruuvi_tag_sensor_records rtsr
                    WHERE rtsr.ruuviTagId = '\(ruuviTagId)'
                    GROUP BY STRFTIME('%s', STRFTIME('%Y-%m-%d %H:%M:%S', rtsr.date) ) / \(Int(interval))
                    ORDER BY date
                    """
                    sqliteEntities = try Record.fetchAll(db, sql: request)
                }
                promise.succeed(value: sqliteEntities.map({ $0.any }))
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    
    func readLast(_ ruuviTagId: String, from: TimeInterval) -> Future<[RuuviTagSensorRecord], RUError> {
        let promise = Promise<[RuuviTagSensorRecord], RUError>()
        readQueue.async { [weak self] in
            var sqliteEntities = [RuuviTagSensorRecord]()
            do {
                try self?.database.dbPool.read { db in
                    let request = Record.order(Record.dateColumn)
                        .filter(Record.ruuviTagIdColumn == ruuviTagId
                                    && Record.dateColumn > Date(timeIntervalSince1970: from))
                    sqliteEntities = try request.fetchAll(db)
                }
                promise.succeed(value: sqliteEntities.map({ $0.any }))
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    func readLast(_ ruuviTag: RuuviTagSensor) -> Future<RuuviTagSensorRecord?, RUError> {
        let promise = Promise<RuuviTagSensorRecord?, RUError>()
        readQueue.async { [weak self] in
            do {
                var sqliteRecord: Record?
                try self?.database.dbPool.read { db in
                    let request = Record.order(Record.dateColumn.desc)
                        .filter(Record.ruuviTagIdColumn == ruuviTag.id)
                    sqliteRecord = try request.fetchOne(db)
                }
                promise.succeed(value: sqliteRecord)
            } catch {
                self?.reportToCrashlytics(error: error)
                promise.fail(error: .persistence(error))
            }
        }
        return promise.future
    }
    
    func update(_ ruuviTag: RuuviTagSensor) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        assert(ruuviTag.macId != nil)
        let entity = Entity(id: ruuviTag.id,
                            macId: ruuviTag.macId,
                            luid: ruuviTag.luid,
                            name: ruuviTag.name,
                            version: ruuviTag.version,
                            isConnectable: ruuviTag.isConnectable)
        
        do {
            try database.dbPool.write { db in
                try entity.update(db)
            }
            promise.succeed(value: true)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func delete(_ ruuviTag: RuuviTagSensor) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        assert(ruuviTag.macId != nil)
        let entity = Entity(id: ruuviTag.id,
                            macId: ruuviTag.macId,
                            luid: ruuviTag.luid,
                            name: ruuviTag.name,
                            version: ruuviTag.version,
                            isConnectable: ruuviTag.isConnectable)
        
        do {
            var success = false
            try database.dbPool.write { db in
                success = try entity.delete(db)
            }
            promise.succeed(value: success)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func deleteAllRecords(_ ruuviTagId: String) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        do {
            var deletedCount = 0
            let request = Record.filter(Record.ruuviTagIdColumn == ruuviTagId)
            try database.dbPool.write { db in
                deletedCount = try request.deleteAll(db)
            }
            promise.succeed(value: deletedCount > 0)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func deleteAllRecords(_ ruuviTagId: String, before date: Date) -> Future<Bool, RUError> {
        let promise = Promise<Bool, RUError>()
        do {
            var deletedCount = 0
            let request = Record.filter(Record.ruuviTagIdColumn == ruuviTagId).filter(Record.dateColumn < date)
            try database.dbPool.write { db in
                deletedCount = try request.deleteAll(db)
            }
            promise.succeed(value: deletedCount > 0)
        } catch {
            reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
}
// MARK: - Private
extension RuuviTagPersistenceSQLite {
    func reportToCrashlytics(error: Error, method: String = #function, line: Int = #line) {
        #if canImport(FirebaseCrashlytics)
        Crashlytics.crashlytics().log("\(method)(line: \(line)")
        Crashlytics.crashlytics().record(error: error)
        #endif
    }
}

extension RuuviTagPersistenceSQLite {
    func readSensorSettings(_ ruuviTag: RuuviTagSensor) -> Future<SensorSettings?, RUError> {
        let promise = Promise<SensorSettings?, RUError>()
        do {
            var sqliteSensorSettings: Settings?
            try self.database.dbPool.read { db in
                let request = Settings.filter(Settings.tagIdColumn == ruuviTag.id)
                sqliteSensorSettings = try request.fetchOne(db)
            }
            promise.succeed(value: sqliteSensorSettings)
        } catch {
            self.reportToCrashlytics(error: error)
            promise.fail(error: .persistence(error))
        }
        return promise.future
    }
    
    func updateOffsetCorrection(type: OffsetCorrectionType, with value: Double?, of ruuviTag: RuuviTagSensor) -> Future<SensorSettings, RUError> {
        let promise = Promise<SensorSettings, RUError>()
        assert(ruuviTag.macId != nil)
        do {
            var sqliteSensorSettings: Settings?
            try database.dbPool.read { db in
                let request = Settings.filter(Settings.tagIdColumn == ruuviTag.id)
                sqliteSensorSettings = try request.fetchOne(db)
            }
            if sqliteSensorSettings != nil {
                switch type {
                case .humidity:
                    sqliteSensorSettings?.humidityOffset = value
                    sqliteSensorSettings?.humidityOffsetDate = value == nil ? nil : Date()
                case .pressure:
                    sqliteSensorSettings?.pressureOffset = value
                    sqliteSensorSettings?.pressureOffsetDate = value == nil ? nil : Date()
                default:
                    sqliteSensorSettings?.temperatureOffset = value
                    sqliteSensorSettings?.temperatureOffsetDate = value == nil ? nil : Date()
                }
                try database.dbPool.write { db in
                    try sqliteSensorSettings!.update(db)
                }
            } else {
                sqliteSensorSettings = Settings(tagId: ruuviTag.id,
                                                temperatureOffset: nil,
                                                temperatureOffsetDate: nil,
                                                humidityOffset: nil,
                                                humidityOffsetDate: nil,
                                                pressureOffset: nil,
                                                pressureOffsetDate: nil)
                switch type {
                case .humidity:
                    sqliteSensorSettings?.humidityOffset = value
                    sqliteSensorSettings?.humidityOffsetDate = value == nil ? nil : Date()
                case .pressure:
                    sqliteSensorSettings?.pressureOffset = value
                    sqliteSensorSettings?.pressureOffsetDate = value == nil ? nil : Date()
                default:
                    sqliteSensorSettings?.temperatureOffset = value
                    sqliteSensorSettings?.temperatureOffsetDate = value == nil ? nil : Date()
                }
                try database.dbPool.write { db in
                    try sqliteSensorSettings!.insert(db)
                }
            }
            promise.succeed(value: sqliteSensorSettings!.sensorSettings)
        } catch let e {
            print(e)
            reportToCrashlytics(error: e)
            promise.fail(error: .persistence(e))
        }
        
        return promise.future
    }
}
