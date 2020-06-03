import Foundation
import GRDB
import RxSwift
import RealmSwift

class RuuviTagRecordSubjectRxSwift {
    let subject: PublishSubject<[AnyRuuviTagSensorRecord]> = PublishSubject()
    var isServing: Bool = false

    private var sqlite: SQLiteContext
    private var realm: RealmContext
    private var ruuviTagId: String

    private var ruuviTagDataRealmToken: NotificationToken?
    private var ruuviTagDataRealmCache = [AnyRuuviTagSensorRecord]()
    private var ruuviTagDataTransactionObserver: TransactionObserver?

    deinit {
        ruuviTagDataRealmToken?.invalidate()
        subject.onCompleted()
    }

    init(ruuviTagId: String, sqlite: SQLiteContext, realm: RealmContext) {
        self.sqlite = sqlite
        self.realm = realm
        self.ruuviTagId = ruuviTagId
    }

    func start() {
        self.isServing = true
        let request = RuuviTagDataSQLite.order(RuuviTagDataSQLite.dateColumn)
                                        .filter(RuuviTagDataSQLite.ruuviTagIdColumn == ruuviTagId)
        let observation = ValueObservation.tracking { db -> [RuuviTagDataSQLite] in
            try! request.fetchAll(db)
        }.removeDuplicates()

        self.ruuviTagDataTransactionObserver = try! observation.start(in: sqlite.database.dbPool) {
            [weak self] records in
            self?.subject.onNext(records.map({ $0.any }))
        }

        let results = self.realm.main.objects(RuuviTagDataRealm.self)
                          .filter("ruuviTag.uuid == %@", ruuviTagId)
                          .sorted(byKeyPath: "date")
        self.ruuviTagDataRealmCache = results.compactMap({ $0.any })
        self.ruuviTagDataRealmToken = results.observe { [weak self] (change) in
            guard let sSelf = self else { return }
            switch change {
            case .initial(let records):
                if records.count > 0 {
                    sSelf.subject.onNext(records.compactMap({ $0.any }))
                }
            case .update(let records, _, _, _):
                if records.count > 0 {
                    sSelf.subject.onNext(records.compactMap({ $0.any }))
                }
            default:
                break
            }
        }
    }
}
