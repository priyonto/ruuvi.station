import Foundation

class ShareConfigurator {
    func configure(view: ShareViewController) {
        let r = AppAssembly.shared.assembler.resolver

        let router = ShareRouter()
        let presenter = SharePresenter()
        presenter.activityPresenter = r.resolve(ActivityPresenter.self)
        presenter.errorPresenter = r.resolve(ErrorPresenter.self)
        presenter.networkService = r.resolve(RuuviNetworkUserApi.self)

        router.transitionHandler = view

        presenter.view = view
        presenter.router = router

        view.output = presenter
    }
}
