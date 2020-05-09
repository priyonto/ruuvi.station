import Foundation
import UIKit

protocol TagChartsViewOutput {
    func viewDidLoad()
    func viewWillAppear()
    func viewWillDisappear()
    func viewDidTransition()
    func viewDidTriggerMenu()
    func viewDidTriggerSettings(for viewModel: TagChartsViewModel)
    func viewDidTriggerCards(for viewModel: TagChartsViewModel)
    func viewDidTriggerSync(for viewModel: TagChartsViewModel)
    func viewDidTriggerExport(for viewModel: TagChartsViewModel)
    func viewDidTriggerClear(for viewModel: TagChartsViewModel)
    func viewDidConfirmToSyncWithTag(for viewModel: TagChartsViewModel)
    func viewDidConfirmToSyncWithWeb(for viewModel: TagChartsViewModel)
    func viewDidConfirmToSyncWithWebKaltiot(for viewModel: TagChartsViewModel)
    func viewDidConfirmToClear(for viewModel: TagChartsViewModel)
}
