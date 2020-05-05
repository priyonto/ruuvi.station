import Foundation

class ConnectionPersistenceUserDefaults: ConnectionPersistence {

    private let prefs = UserDefaults.standard
    private let keepConnectionArrayUDKey = "ConnectionPersistenceUserDefaults.keepConnection.array"

    var keepConnectionUUIDs: [AnyLocalIdentifier] {
        let strings = prefs.array(forKey: keepConnectionArrayUDKey) as? [String]
        return strings?.map({ $0.luid.any }) ?? []
    }

    func keepConnection(to luid: LocalIdentifier) -> Bool {
        let uuid = luid.value
        assert(uuid.count == 36)
        if let array = prefs.array(forKey: keepConnectionArrayUDKey) as? [String] {
            return array.contains(uuid)
        } else {
            return false
        }
    }

    func setKeepConnection(_ value: Bool, for luid: LocalIdentifier) {
        let uuid = luid.value
        assert(uuid.count == 36)
        if value {
            if var array = prefs.array(forKey: keepConnectionArrayUDKey) as? [String],
                !array.contains(uuid) {
                array.append(uuid)
                prefs.set(array, forKey: keepConnectionArrayUDKey)
                NotificationCenter.default.post(name: .ConnectionPersistenceDidStartToKeepConnection,
                                                object: nil,
                                                userInfo:
                    [CPDidStartToKeepConnectionKey.uuid: uuid])
            } else {
                var array = [String]()
                array.append(uuid)
                prefs.set(array, forKey: keepConnectionArrayUDKey)
                NotificationCenter.default.post(name: .ConnectionPersistenceDidStartToKeepConnection,
                                                object: nil,
                                                userInfo:
                    [CPDidStartToKeepConnectionKey.uuid: uuid])
            }
        } else {
            if var array = prefs.array(forKey: keepConnectionArrayUDKey) as? [String],
                array.contains(uuid) {
                array.removeAll(where: { $0 == uuid })
                prefs.set(array, forKey: keepConnectionArrayUDKey)
                NotificationCenter.default.post(name: .ConnectionPersistenceDidStopToKeepConnection,
                                                object: nil,
                                                userInfo:
                    [CPDidStopToKeepConnectionKey.uuid: uuid])
            }
        }
    }
}
