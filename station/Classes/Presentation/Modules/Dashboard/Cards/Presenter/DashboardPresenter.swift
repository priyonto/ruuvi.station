import Foundation
import RealmSwift
import BTKit

class DashboardPresenter: DashboardModuleInput {
    weak var view: DashboardViewInput!
    var router: DashboardRouterInput!
    var realmContext: RealmContext!
    var errorPresenter: ErrorPresenter!
    var settings: Settings!
    var backgroundPersistence: BackgroundPersistence!
    var scanner: BTScanner!
    var webTagService: WebTagService!
    var permissionPresenter: PermissionPresenter!
    var pushNotificationsManager: PushNotificationsManager!
    var permissionsManager: PermissionsManager!
    
    private var ruuviTagsToken: NotificationToken?
    private var webTagsToken: NotificationToken?
    private var webTagsDataTokens = [NotificationToken]()
    private var observeTokens = [ObservationToken]()
    private var temperatureUnitToken: NSObjectProtocol?
    private var humidityUnitToken: NSObjectProtocol?
    private var backgroundToken: NSObjectProtocol?
    private var webTagDaemonFailureToken: NSObjectProtocol?
    private var ruuviTagAdvertisementDaemonFailureToken: NSObjectProtocol?
    private var stateToken: ObservationToken?
    private var webTags: Results<WebTagRealm>? {
        didSet {
            syncViewModels()
        }
    }
    private var ruuviTags: Results<RuuviTagRealm>? {
        didSet {
            syncViewModels()
        }
    }
    private var viewModels = [DashboardTagViewModel]() {
        didSet {
            view.viewModels = viewModels
        }
    }
    
    deinit {
        ruuviTagsToken?.invalidate()
        webTagsToken?.invalidate()
        observeTokens.forEach( { $0.invalidate() } )
        webTagsDataTokens.forEach({ $0.invalidate() })
        stateToken?.invalidate()
        if let temperatureUnitToken = temperatureUnitToken {
            NotificationCenter.default.removeObserver(temperatureUnitToken)
        }
        if let humidityUnitToken = humidityUnitToken {
            NotificationCenter.default.removeObserver(humidityUnitToken)
        }
        if let backgroundToken = backgroundToken {
            NotificationCenter.default.removeObserver(backgroundToken)
        }
        if let webTagDaemonFailureToken = webTagDaemonFailureToken {
            NotificationCenter.default.removeObserver(webTagDaemonFailureToken)
        }
        if let ruuviTagAdvertisementDaemonFailureToken = ruuviTagAdvertisementDaemonFailureToken{
            NotificationCenter.default.removeObserver(ruuviTagAdvertisementDaemonFailureToken)
        }
    }
}

// MARK: - DashboardViewOutput
extension DashboardPresenter: DashboardViewOutput {
    func viewDidLoad() {
        startObservingRuuviTags()
        startObservingWebTags()
        startObservingSettingsChanges()
        startObservingBackgroundChanges()
        startObservingDaemonsErrors()
        pushNotificationsManager.registerForRemoteNotifications()
    }
    
    func viewWillAppear() {
        startObservingBluetoothState()
    }
    
    func viewWillDisappear() {
        stopObservingBluetoothState()
    }
    
    func viewDidTriggerMenu() {
        router.openMenu(output: self)
    }
    
    func viewDidTriggerSettings(for viewModel: DashboardTagViewModel) {
        if viewModel.type == .ruuvi, let ruuviTag = ruuviTags?.first(where: { $0.uuid == viewModel.uuid.value }) {
            router.openTagSettings(ruuviTag: ruuviTag, humidity: viewModel.relativeHumidity.value)
        } else if viewModel.type == .web, let webTag = webTags?.first(where: { $0.uuid == viewModel.uuid.value }) {
            router.openWebTagSettings(webTag: webTag)
        }
    }
    
    func viewDidTriggerChart(for viewModel: DashboardTagViewModel) {
        if let uuid = viewModel.uuid.value {
            router.openTagCharts(uuid: uuid, output: self)
        }
    }
}

// MARK: - MenuModuleOutput
extension DashboardPresenter: MenuModuleOutput {
    func menu(module: MenuModuleInput, didSelectAddRuuviTag sender: Any?) {
        module.dismiss()
        router.openDiscover()
    }
    
    func menu(module: MenuModuleInput, didSelectSettings sender: Any?) {
        module.dismiss()
        router.openSettings()
    }
    
    func menu(module: MenuModuleInput, didSelectAbout sender: Any?) {
        module.dismiss()
        router.openAbout()
    }
    
    func menu(module: MenuModuleInput, didSelectGetMoreSensors sender: Any?) {
        module.dismiss()
        router.openRuuviWebsite()
    }
}

// MARK: - TagChartsModuleOutput
extension DashboardPresenter: TagChartsModuleOutput {
    func tagCharts(module: TagChartsModuleInput, didScrollTo uuid: String) {
        if let index = viewModels.firstIndex(where: { $0.uuid.value == uuid }) {
            view.scroll(to: index, immediately: true)
        }
    }
}

// MARK: - DashboardRouterDelegate
extension DashboardPresenter: DashboardRouterDelegate {
    func shouldDismissDiscover() -> Bool {
        return viewModels.count > 0
    }
}

// MARK: - Private
extension DashboardPresenter {

    private func syncViewModels() {
        if ruuviTags != nil && webTags != nil {
            let ruuviViewModels = ruuviTags?.compactMap({ (ruuviTag) -> DashboardTagViewModel in
                let viewModel = DashboardTagViewModel(ruuviTag)
                viewModel.humidityUnit.value = settings.humidityUnit
                viewModel.background.value = backgroundPersistence.background(for: ruuviTag.uuid)
                viewModel.temperatureUnit.value = settings.temperatureUnit
                return viewModel
            }) ?? []
            let webViewModels = webTags?.compactMap({ (webTag) -> DashboardTagViewModel in
                let viewModel = DashboardTagViewModel(webTag)
                viewModel.humidityUnit.value = settings.humidityUnit
                viewModel.background.value = backgroundPersistence.background(for: webTag.uuid)
                viewModel.temperatureUnit.value = settings.temperatureUnit
                return viewModel
            }) ?? []
            viewModels = ruuviViewModels + webViewModels
            
            // if no tags, open discover
            if viewModels.count == 0 {
                router.openDiscover()
            }
        }
    }

    private func startObservingBluetoothState() {
        stateToken = scanner.state(self, closure: { (observer, state) in
            if state != .poweredOn {
                observer.view.showBluetoothDisabled()
            }
        })
    }
    
    private func stopObservingBluetoothState() {
        stateToken?.invalidate()
    }
    
    
    private func startObservingSettingsChanges() {
        temperatureUnitToken = NotificationCenter.default.addObserver(forName: .TemperatureUnitDidChange, object: nil, queue: .main) { [weak self] (notification) in
            self?.viewModels.forEach( { $0.temperatureUnit.value = self?.settings.temperatureUnit } )
        }
        humidityUnitToken = NotificationCenter.default.addObserver(forName: .HumidityUnitDidChange, object: nil, queue: .main, using: { [weak self] (notification) in
            self?.viewModels.forEach( { $0.humidityUnit.value = self?.settings.humidityUnit } )
        })
    }
    
    private func startScanningRuuviTags() {
        observeTokens.forEach( { $0.invalidate() } )
        observeTokens.removeAll()
        for viewModel in viewModels {
            if viewModel.type == .ruuvi, let uuid = viewModel.uuid.value {
                observeTokens.append(scanner.observe(self, uuid: uuid) { [weak self] (observer, device) in
                    if let ruuviTag = device.ruuvi?.tag,
                        let viewModel = self?.viewModels.first(where: { $0.uuid.value == ruuviTag.uuid }) {
                        viewModel.update(with: ruuviTag)
                    }
                })
            }
        }
    }
    
    private func startObservingWebTagsData() {
        webTagsDataTokens.forEach({ $0.invalidate() })
        webTagsDataTokens.removeAll()
        
        webTags?.forEach({ webTag in
            webTagsDataTokens.append(webTag.data.observe { [weak self] (change) in
                switch change {
                case .initial(let data):
                    if let last = data.sorted(byKeyPath: "date").last {
                        self?.viewModels
                            .filter({ $0.uuid.value == webTag.uuid })
                            .forEach( { $0.update(last)})
                    }
                case .update(let data, _, _, _):
                    if let last = data.sorted(byKeyPath: "date").last {
                        self?.viewModels
                            .filter({ $0.uuid.value == webTag.uuid })
                            .forEach( { $0.update(last)})
                    }
                case .error(let error):
                    self?.errorPresenter.present(error: error)
                }
            })
        })
    }
    
    private func startObservingWebTags() {
        webTags = realmContext.main.objects(WebTagRealm.self)
        webTagsToken = webTags?.observe({ [weak self] (change) in
            switch change {
            case .initial(let webTags):
                self?.webTags = webTags
                self?.startObservingWebTagsData()
            case .update(let webTags, _, let insertions, _):
                self?.webTags = webTags
                if let ii = insertions.last {
                    let uuid = webTags[ii].uuid
                    if let index = self?.viewModels.firstIndex(where: { $0.uuid.value == uuid }) {
                        self?.view.scroll(to: index)
                    }
                }
                self?.startObservingWebTagsData()
            case .error(let error):
                self?.errorPresenter.present(error: error)
            }
        })
    }
    
    private func startObservingRuuviTags() {
        ruuviTags = realmContext.main.objects(RuuviTagRealm.self)
        ruuviTagsToken = ruuviTags?.observe { [weak self] (change) in
            switch change {
            case .initial(let ruuviTags):
                self?.ruuviTags = ruuviTags
                self?.startScanningRuuviTags()
            case .update(let ruuviTags, _, let insertions, _):
                self?.ruuviTags = ruuviTags
                if let ii = insertions.last {
                    let uuid = ruuviTags[ii].uuid
                    if let index = self?.viewModels.firstIndex(where: { $0.uuid.value == uuid }) {
                        self?.view.scroll(to: index)
                    }
                }
                self?.startScanningRuuviTags()
            case .error(let error):
                self?.errorPresenter.present(error: error)
            }
        }
    }
    
    private func startObservingBackgroundChanges() {
        backgroundToken = NotificationCenter.default.addObserver(forName: .BackgroundPersistenceDidChangeBackground, object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo, let uuid = userInfo[BackgroundPersistenceDidChangeBackgroundKey.uuid] as? String {
                if let viewModel = self?.view.viewModels.first(where: { $0.uuid.value == uuid }) {
                    viewModel.background.value = self?.backgroundPersistence.background(for: uuid)
                }
            }
        }
    }
    
    func startObservingDaemonsErrors() {
        webTagDaemonFailureToken = NotificationCenter.default.addObserver(forName: .WebTagDaemonDidFail, object: nil, queue: .main) { [weak self] notification in
            if let userInfo = notification.userInfo, let error = userInfo[WebTagDaemonDidFailKey.error] as? RUError {
                if case .core(let coreError) = error, coreError == .locationPermissionDenied {
                    self?.permissionPresenter.presentNoLocationPermission()
                } else if case .core(let coreError) = error, coreError == .locationPermissionNotDetermined {
                    self?.permissionsManager.requestLocationPermission { [weak self] (granted) in
                        if !granted {
                            self?.permissionPresenter.presentNoLocationPermission()
                        }
                    }
                } else if case .parse(let parseError) = error, parseError == OWMError.apiLimitExceeded {
                    self?.view.showWebTagAPILimitExceededError()
                } else {
                    self?.errorPresenter.present(error: error)
                }
            }
        }
        
        ruuviTagAdvertisementDaemonFailureToken = NotificationCenter.default.addObserver(forName: .RuuviTagAdvertisementDaemonDidFail, object: nil, queue: .main, using: { [weak self] (notification) in
            if let userInfo = notification.userInfo, let error = userInfo[WebTagDaemonDidFailKey.error] as? RUError {
                self?.errorPresenter.present(error: error)
            }
        })
        
    }
}
