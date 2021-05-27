import Foundation
import RuuviOntology
import RealmSwift

extension RuuviTagRealm: RuuviTagSensor {
    public var luid: LocalIdentifier? {
        return uuid.luid
    }

    public var macId: MACIdentifier? {
        return mac?.mac
    }

    public var any: AnyRuuviTagSensor {
        return AnyRuuviTagSensor(
            object: RuuviTagSensorStruct(
                version: version,
                luid: luid,
                macId: macId,
                isConnectable: isConnectable,
                name: name,
                isClaimed: isClaimed,
                isOwner: isOwner,
                owner: owner
            )
        )
    }

    public var isClaimed: Bool {
        return false
    }
    public var isOwner: Bool {
        return true
    }
    public var owner: String? {
        return nil
    }
}
