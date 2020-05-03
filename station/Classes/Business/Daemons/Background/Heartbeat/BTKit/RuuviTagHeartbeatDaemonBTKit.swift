import Foundation
import BTKit
import RealmSwift

class RuuviTagHeartbeatDaemonBTKit: BackgroundWorker, RuuviTagHeartbeatDaemon {

    var background: BTBackground!
    var localNotificationsManager: LocalNotificationsManager!
    var connectionPersistence: ConnectionPersistence!
    var ruuviTagTank: RuuviTagTank!
    var alertService: AlertService!
    var settings: Settings!
    var pullWebDaemon: PullWebDaemon!

    private var realm: Realm!
    private var ruuviTags: Results<RuuviTagRealm>?
    private var connectTokens = [String: ObservationToken]()
    private var disconnectTokens = [String: ObservationToken]()
    private var connectionAddedToken: NSObjectProtocol?
    private var connectionRemovedToken: NSObjectProtocol?
    private var savedDate = [String: Date]() // uuid:date
    private var ruuviTagsToken: NotificationToken?

    @objc private class RuuviTagHeartbeatDaemonPair: NSObject {
        var uuid: String
        var device: RuuviTag

        init(uuid: String, device: RuuviTag) {
            self.uuid = uuid
            self.device = device
        }
    }

    override init() {
        super.init()
        connectionAddedToken = NotificationCenter
            .default
            .addObserver(forName: .ConnectionPersistenceDidStartToKeepConnection,
                         object: nil,
                         queue: .main,
                         using: { [weak self] (notification) in
            guard let sSelf = self else { return }
            if let userInfo = notification.userInfo,
                let uuid = userInfo[CPDidStartToKeepConnectionKey.uuid] as? String {
                sSelf.perform(#selector(RuuviTagHeartbeatDaemonBTKit.connect(uuid:)),
                on: sSelf.thread,
                with: uuid,
                waitUntilDone: false,
                modes: [RunLoop.Mode.default.rawValue])
            }
        })

        connectionRemovedToken = NotificationCenter
            .default
            .addObserver(forName: .ConnectionPersistenceDidStopToKeepConnection,
                         object: nil,
                         queue: .main,
                         using: { [weak self] (notification) in
            guard let sSelf = self else { return }
            if let userInfo = notification.userInfo, let uuid = userInfo[CPDidStopToKeepConnectionKey.uuid] as? String {
                sSelf.perform(#selector(RuuviTagHeartbeatDaemonBTKit.disconnect(uuid:)),
                on: sSelf.thread,
                with: uuid,
                waitUntilDone: false,
                modes: [RunLoop.Mode.default.rawValue])
            }
        })
    }

    deinit {
        invalidateTokens()
        if let connectionAddedToken = connectionAddedToken {
            NotificationCenter.default.removeObserver(connectionAddedToken)
        }
        if let connectionRemovedToken = connectionRemovedToken {
            NotificationCenter.default.removeObserver(connectionRemovedToken)
        }
    }

    func start() {
        start { [weak self] in
            autoreleasepool {
                self?.invalidateTokens()
                self?.realm = try! Realm()
                self?.ruuviTags = self?.realm.objects(RuuviTagRealm.self).filter("isConnectable == true")
                self?.ruuviTagsToken = self?.ruuviTags?.observe({ [weak self] (change) in
                    switch change {
                    case .initial:
                        break
                    case .update(_, let deletions, let insertions, _):
                        if deletions.count > 0 || insertions.count > 0 {
                            self?.handleRuuviTagsChange()
                        }
                    case .error(let error):
                        self?.post(error: RUError.persistence(error))
                    }
                })
                self?.connectionPersistence.keepConnectionUUIDs
                    .filter({ (uuid) -> Bool in
                        self?.ruuviTags?.contains(where: { $0.uuid == uuid }) ?? false
                    }).forEach({ self?.connect(uuid: $0)})
            }
        }
    }

    func stop() {
        perform(#selector(RuuviTagHeartbeatDaemonBTKit.stopDaemon),
                on: thread,
                with: nil,
                waitUntilDone: false,
                modes: [RunLoop.Mode.default.rawValue])
    }

    @objc private func stopDaemon() {
        autoreleasepool {
            invalidateTokens()
            connectionPersistence.keepConnectionUUIDs.forEach({ disconnect(uuid: $0) })
            realm.invalidate()
            stopWork()
        }
    }
}

// MARK: - Handlers
extension RuuviTagHeartbeatDaemonBTKit {
    private func connectedHandler(for uuid: String) -> ((RuuviTagHeartbeatDaemonBTKit, BTConnectResult) -> Void)? {
        return { observer, result in
            switch result {
            case .already:
                break // already connected, do nothing
            case .just:
               if observer.alertService.isOn(type: .connection, for: uuid) {
                   observer.notifyDidConnect(uuid: uuid)
                }
            case .failure(let error):
               observer.post(error: RUError.btkit(error))
            case .disconnected:
               if observer.alertService.isOn(type: .connection, for: uuid) {
                   observer.notifyDidDisconnect(uuid: uuid)
                }
            }
        }
    }

    private func heartbeatHandler() -> ((RuuviTagHeartbeatDaemonBTKit, BTDevice) -> Void)? {
        return { observer, device in
            observer.pullWebDaemon.wakeUp()
            if let ruuviTag = device.ruuvi?.tag {
                observer.alertService.process(heartbeat: ruuviTag)
               if observer.settings.saveHeartbeats {
                    let uuid = ruuviTag.uuid
                    let interval = observer.settings.saveHeartbeatsIntervalMinutes
                    if let date = observer.savedDate[uuid] {
                        if Date().timeIntervalSince(date) > TimeInterval(interval * 60) {
                            observer.ruuviTagTank.create(ruuviTag)
                            observer.savedDate[uuid] = Date()
                        }
                    } else {
                        observer.ruuviTagTank.create(ruuviTag)
                        observer.savedDate[uuid] = Date()
                    }
                }
            }
        }
    }

    private func disconnectedHandler(for uuid: String) ->
        ((RuuviTagHeartbeatDaemonBTKit, BTDisconnectResult) -> Void)? {
        return { observer, result in
            switch result {
            case .stillConnected:
                break // do nothing
            case .already:
                break // do nothing
            case .bluetoothWasPoweredOff:
               if observer.alertService.isOn(type: .connection, for: uuid) {
                    observer.notifyDidDisconnect(uuid: uuid)
                }
            case .just:
               if observer.alertService.isOn(type: .connection, for: uuid) {
                    observer.notifyDidDisconnect(uuid: uuid)
                }
            case .failure(let error):
                observer.post(error: RUError.btkit(error))
            }
        }
    }
}

// MARK: - Private
extension RuuviTagHeartbeatDaemonBTKit {
    private func handleRuuviTagsChange() {
        autoreleasepool {
            connectionPersistence.keepConnectionUUIDs
                .filter { (uuid) -> Bool in
                    ruuviTags?.contains(where: { $0.uuid == uuid }) ?? false
                        && !connectTokens.keys.contains(uuid)
                }.forEach({ connect(uuid: $0) })
            connectionPersistence.keepConnectionUUIDs
                .filter { (uuid) -> Bool in
                    if let contains = ruuviTags?.contains(where: { $0.uuid == uuid }) {
                        return !contains && connectTokens.keys.contains(uuid)
                    } else {
                        return connectTokens.keys.contains(uuid)
                    }
                }.forEach({ disconnect(uuid: $0) })
        }
     }

     @objc private func connect(uuid: String) {
         disconnectTokens[uuid]?.invalidate()
         disconnectTokens.removeValue(forKey: uuid)
         connectTokens[uuid] = background
             .connect(for: self,
                      uuid: uuid,
                      options: [.callbackQueue(.untouch)],
                      connected: connectedHandler(for: uuid),
                      heartbeat: heartbeatHandler(),
                      disconnected: disconnectedHandler(for: uuid))
     }

     @objc private func disconnect(uuid: String) {
         connectTokens[uuid]?.invalidate()
         connectTokens.removeValue(forKey: uuid)
         disconnectTokens[uuid] = background
             .disconnect(for: self,
                         uuid: uuid,
                         options: [.callbackQueue(.untouch)],
                         result: disconnectedHandler(for: uuid))
     }

     private func invalidateTokens() {
        autoreleasepool {
            ruuviTagsToken?.invalidate()
            connectTokens.values.forEach({ $0.invalidate() })
            connectTokens.removeAll()
            disconnectTokens.values.forEach({ $0.invalidate() })
            disconnectTokens.removeAll()
        }
     }

    private func post(error: Error) {
        DispatchQueue.main.async {
            NotificationCenter
                .default
                .post(name: .RuuviTagHeartbeatDaemonDidFail,
                      object: nil,
                      userInfo: [RuuviTagHeartbeatDaemonDidFailKey.error: error])
        }
    }

    private func notifyDidDisconnect(uuid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.localNotificationsManager.showDidDisconnect(uuid: uuid)
        }
    }

    private func notifyDidConnect(uuid: String) {
        DispatchQueue.main.async { [weak self] in
            self?.localNotificationsManager.showDidConnect(uuid: uuid)
        }
    }
}
