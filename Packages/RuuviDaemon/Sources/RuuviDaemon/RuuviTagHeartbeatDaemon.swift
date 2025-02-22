import Foundation
import Future

extension Notification.Name {
    public static let RuuviTagHeartbeatDaemonDidFail = Notification.Name("RuuviTagHeartbeatDaemonDidFail")
    public static let RuuviTagHeartBeatDaemonShouldRestart = Notification.Name("RuuviTagHeartBeatDaemonShouldRestart")
}

public enum RuuviTagHeartbeatDaemonDidFailKey: String {
    case error = "RuuviDaemonError" // RuuviDaemonError
}

public protocol RuuviTagHeartbeatDaemon {
    func start()
    func stop()
    func restart()
}

public protocol RuuviTagHeartbeatDaemonTitles {
    var didConnect: String { get }
    var didDisconnect: String { get }
}
