import Foundation
import Future

class DataPruningOperationsManager {

    var settings: Settings!
    var virtualTagTrunk: VirtualTagTrunk!
    var virtualTagTank: VirtualTagTank!
    var ruuviTagTrunk: RuuviTagTrunk!
    var ruuviTagTank: RuuviTagTank!

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
        ruuviTagTrunk.readAll().on(success: { [weak self] ruuviTags in
            guard let sSelf = self else { return }
            let ops = ruuviTags.map({
                RuuviTagDataPruningOperation(id: $0.id,
                                             ruuviTagTank: sSelf.ruuviTagTank,
                                             settings: sSelf.settings)
            })
            promise.succeed(value: ops)
        }, failure: { error in
            promise.fail(error: error)
        })
        return promise.future
    }

}
