import Foundation
import GRDB
import Combine
import RealmSwift
import RuuviOntology
import RuuviContext
#if canImport(RuuviOntologyRealm)
import RuuviOntologyRealm
#endif
#if canImport(RuuviOntologySQLite)
import RuuviOntologySQLite
#endif

final class RuuviTagSubjectCombine {
    var sqlite: SQLiteContext
    var realm: RealmContext

    let insertSubject = PassthroughSubject<AnyRuuviTagSensor, Never>()
    let updateSubject = PassthroughSubject<AnyRuuviTagSensor, Never>()
    let deleteSubject = PassthroughSubject<AnyRuuviTagSensor, Never>()

    private var ruuviTagController: FetchedRecordsController<RuuviTagSQLite>
    private var ruuviTagsRealmToken: NotificationToken?
    private var ruuviTagRealmCache = [AnyRuuviTagSensor]()

    deinit {
        ruuviTagsRealmToken?.invalidate()
    }

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    init(sqlite: SQLiteContext, realm: RealmContext) {
        self.sqlite = sqlite
        self.realm = realm

        let request = RuuviTagSQLite.order(RuuviTagSQLite.versionColumn)
        self.ruuviTagController = try! FetchedRecordsController(sqlite.database.dbPool, request: request)
        try! self.ruuviTagController.performFetch()

        self.ruuviTagController.trackChanges(onChange: { [weak self] _, record, event in
            guard let sSelf = self else { return }
            switch event {
            case .insertion:
                DispatchQueue.main.async {
                    sSelf.insertSubject.send(record.any)
                }
            case .update:
                DispatchQueue.main.async {
                    sSelf.updateSubject.send(record.any)
                }
            case .deletion:
                DispatchQueue.main.async {
                    sSelf.deleteSubject.send(record.any)
                }
            case .move:
                break
            }
        })

        DispatchQueue.main.async { [weak self] in
            guard let sSelf = self else { return }
            let results = sSelf.realm.main.objects(RuuviTagRealm.self)
            sSelf.ruuviTagRealmCache = results.map({ $0.struct.any })
            sSelf.ruuviTagsRealmToken = results.observe { [weak self] (change) in
                guard let sSelf = self else { return }
                switch change {
                case .update(let ruuviSensors, let deletions, let insertions, let modifications):
                    for del in deletions {
                        sSelf.deleteSubject.send(sSelf.ruuviTagRealmCache[del].struct.any)
                    }
                    sSelf.ruuviTagRealmCache = sSelf.ruuviTagRealmCache
                                                    .enumerated()
                                                    .filter { !deletions.contains($0.offset) }
                                                    .map { $0.element }
                    for ins in insertions {
                        sSelf.insertSubject.send(ruuviSensors[ins].struct.any)
                        // TODO: test if ok with multiple
                        sSelf.ruuviTagRealmCache.insert(ruuviSensors[ins].struct.any, at: ins)
                    }
                    for mod in modifications {
                        sSelf.updateSubject.send(ruuviSensors[mod].struct.any)
                        sSelf.ruuviTagRealmCache[mod] = ruuviSensors[mod].struct.any
                    }
                default:
                    break
                }
            }
        }
    }
}
