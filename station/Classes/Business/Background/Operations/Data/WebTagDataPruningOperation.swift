import Foundation
import RuuviLocal

class WebTagDataPruningOperation: AsyncOperation {

    private var id: String
    private var settings: RuuviLocalSettings
    private var virtualTagTank: VirtualTagTank

    init(id: String, virtualTagTank: VirtualTagTank, settings: RuuviLocalSettings) {
        self.id = id
        self.virtualTagTank = virtualTagTank
        self.settings = settings
    }

    override func main() {
        let offset = settings.dataPruningOffsetHours
        let date = Calendar.current.date(byAdding: .hour,
                                         value: -offset,
                                         to: Date()) ?? Date()
        virtualTagTank.deleteAllRecords(id, before: date).on(failure: { error in
            print(error.localizedDescription)
        }, completion: {
            self.state = .finished
        })
    }
}
