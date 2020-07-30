import Foundation
import BTKit

protocol CardsViewInput: ViewInput {
    var viewModels: [CardsViewModel] { get set }
    var currentPage: Int { get }
    func scroll(to index: Int, immediately: Bool)
    func showBluetoothDisabled()
    func showSwipeLeftRightHint()
    func showWebTagAPILimitExceededError()
    func showKeepConnectionDialog(for viewModel: CardsViewModel)
    func showReverseGeocodingFailed()
}

extension CardsViewInput {
    func scroll(to index: Int) {
        scroll(to: index, immediately: false)
    }
}
