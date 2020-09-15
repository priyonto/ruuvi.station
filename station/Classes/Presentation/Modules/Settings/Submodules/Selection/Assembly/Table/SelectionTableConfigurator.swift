import Foundation

class SelectionTableConfigurator {
    func configure(view: SelectionTableViewController) {

        let router = SelectionRouter()
        router.transitionHandler = view

        let presenter = SelectionPresenter()
        presenter.view = view
        presenter.router = router

        view.output = presenter
    }
}
