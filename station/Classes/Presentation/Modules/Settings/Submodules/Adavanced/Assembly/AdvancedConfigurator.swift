import Foundation

class AdvancedConfigurator {
    func configure(view: AdvancedTableViewController) {
        let r = AppAssembly.shared.assembler.resolver

        let router = AdvancedRouter()
        router.transitionHandler = view

        let presenter = AdvancedPresenter()
        presenter.view = view
        presenter.router = router
        presenter.settings = r.resolve(Settings.self)

        view.output = presenter
    }
}
