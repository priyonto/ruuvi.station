import Foundation
import BTKit

protocol CardsViewInput: ViewInput {
    var viewModels: [CardsViewModel] { get set }
    var currentPage: Int { get }
    func scroll(to index: Int, immediately: Bool, animated: Bool)
    func showBluetoothDisabled()
    func showSwipeLeftRightHint()
    func showWebTagAPILimitExceededError()
    func showKeepConnectionDialogChart(for viewModel: CardsViewModel)
    func showKeepConnectionDialogSettings(for viewModel: CardsViewModel, scrollToAlert: Bool)
    func showReverseGeocodingFailed()
}

extension CardsViewInput {
    func scroll(to index: Int) {
        scroll(to: index, immediately: false, animated: true)
    }
}
