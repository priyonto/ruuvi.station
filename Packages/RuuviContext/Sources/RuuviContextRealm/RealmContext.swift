import RealmSwift

public protocol RealmContext {
    var bg: Realm! { get }
    var main: Realm { get }
    var bgWorker: Worker { get }
}
