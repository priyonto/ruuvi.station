import Foundation

class MigrationManagerSensorSettings: MigrationManager {
    // persistence
    var calibrationPersistence: CalibrationPersistence!
    var errorPresenter: ErrorPresenter!
    var ruuviTagTrunk: RuuviTagTrunk!

    @UserDefault("MigrationManagerSensorSettings.didMigrateSensorSettings", defaultValue: false)
    private var didMigrateSensorSettings: Bool

    func migrateIfNeeded() {
        if !didMigrateSensorSettings {
            ruuviTagTrunk.readAll().on(success: { ruuviTags in
                ruuviTags.forEach { ruuviTag in
                    if let luid = ruuviTag.luid {
                        let pair = self.calibrationPersistence.humidityOffset(for: luid)
                        self.ruuviTagTrunk.updateOffsetCorrection(
                            type: .humidity,
                            with: pair.0 / 100.0, // have to divide to 100
                            of: ruuviTag,
                            lastOriginalRecord: nil
                        ).on(success: { _ in
                            self.calibrationPersistence
                                .setHumidity(date: nil, offset: 0.0, for: luid)
                        })
                    }
                }
            }, failure: {[weak self] error in
                self?.errorPresenter.present(error: error)
            })
            didMigrateSensorSettings = true
        }
    }
}
