#if canImport(Combine)
import Foundation
import GRDB
import Combine
import RealmSwift
import RuuviOntology
import RuuviContext

@available(iOS 13, *)
class SensorSettingsCombine {
    var ruuviTagId: String
    var sqlite: SQLiteContext
    var realm: RealmContext

    let insertSubject = PassthroughSubject<SensorSettings, Never>()
    let updateSubject = PassthroughSubject<SensorSettings, Never>()
    let deleteSubject = PassthroughSubject<SensorSettings, Never>()

    private var ruuviTagController: FetchedRecordsController<SensorSettingsSQLite>
    private var ruuviTagsRealmToken: NotificationToken?
    private var ruuviTagRealmCache = [SensorSettings]()

    deinit {
        ruuviTagsRealmToken?.invalidate()
    }

    // swiftlint:disable:next cyclomatic_complexity
    init(ruuviTagId: String, sqlite: SQLiteContext, realm: RealmContext) {
        self.ruuviTagId = ruuviTagId
        self.sqlite = sqlite
        self.realm = realm

        let request = SensorSettingsSQLite.filter(SensorSettingsSQLite.ruuviTagIdColumn == ruuviTagId)
        self.ruuviTagController = try! FetchedRecordsController(sqlite.database.dbPool, request: request)
        try! self.ruuviTagController.performFetch()

        self.ruuviTagController.trackChanges(onChange: { [weak self] _, record, event in
            guard let sSelf = self else { return }
            switch event {
            case .insertion:
                sSelf.insertSubject.send(record.sensorSettings)
            case .update:
                sSelf.updateSubject.send(record.sensorSettings)
            case .deletion:
                sSelf.deleteSubject.send(record.sensorSettings)
            case .move:
                break
            }
        })

        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            let results = sSelf.realm.main.objects(SensorSettingsRealm.self)
            sSelf.ruuviTagRealmCache = results.map({ $0.sensorSettings })
            sSelf.ruuviTagsRealmToken = results.observe { [weak self] (change) in
                guard let sSelf = self else { return }
                switch change {
                case .update(let sensorSettings, let deletions, let insertions, let modifications):
                    for del in deletions {
                        sSelf.deleteSubject.send(sSelf.ruuviTagRealmCache[del])
                    }
                    sSelf.ruuviTagRealmCache = sSelf.ruuviTagRealmCache
                                                    .enumerated()
                                                    .filter { !deletions.contains($0.offset) }
                                                    .map { $0.element }
                    for ins in insertions {
                        sSelf.insertSubject.send(sensorSettings[ins].sensorSettings)
                        // TODO: test if ok with multiple
                        sSelf.ruuviTagRealmCache.insert(sensorSettings[ins].sensorSettings, at: ins)
                    }
                    for mod in modifications {
                        sSelf.updateSubject.send(sensorSettings[mod].sensorSettings)
                        sSelf.ruuviTagRealmCache[mod] = sensorSettings[mod].sensorSettings
                    }
                default:
                    break
                }
            }
        }
    }
}
#endif
