import Foundation
import Future
import RuuviStorage
import RuuviLocal
import RuuviPool

class DataPruningOperationsManager {

    var settings: RuuviLocalSettings!
    var virtualTagTrunk: VirtualTagTrunk!
    var virtualTagTank: VirtualTagTank!
    var ruuviStorage: RuuviStorage!
    var ruuviPool: RuuviPool!

    func webTagPruningOperations() -> Future<[Operation], RUError> {
        let promise = Promise<[Operation], RUError>()
        virtualTagTrunk.readAll().on(success: { [weak self] virtualTags in
            guard let sSelf = self else { return }
            let ops = virtualTags.map({
                WebTagDataPruningOperation(id: $0.id,
                                           virtualTagTank: sSelf.virtualTagTank,
                                           settings: sSelf.settings)
            })
            promise.succeed(value: ops)
        }, failure: { error in
            promise.fail(error: error)
        })
        return promise.future
    }

    func ruuviTagPruningOperations() -> Future<[Operation], RUError> {
        let promise = Promise<[Operation], RUError>()
        ruuviStorage.readAll().on(success: { [weak self] ruuviTags in
            guard let sSelf = self else { return }
            let ops = ruuviTags.map({
                RuuviTagDataPruningOperation(
                    id: $0.id,
                    ruuviPool: sSelf.ruuviPool,
                    settings: sSelf.settings
                )
            })
            promise.succeed(value: ops)
        }, failure: { error in
            promise.fail(error: .ruuviStorage(error))
        })
        return promise.future
    }

}
