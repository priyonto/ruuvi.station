import Swinject
import BTKit
import RuuviContext
import RuuviStorage
import RuuviReactor
import RuuviPersistence
import RuuviLocal
import RuuviPool
import RuuviService
import RuuviCloud
import RuuviCore
import RuuviDaemon

// swiftlint:disable:next type_body_length
class BusinessAssembly: Assembly {

    // swiftlint:disable:next function_body_length
    func assemble(container: Container) {

        container.register(AlertService.self) { r in
            let service = AlertServiceImpl()
            service.alertPersistence = r.resolve(AlertPersistence.self)
            service.calibrationService = r.resolve(CalibrationService.self)
            return service
        }.inObjectScope(.container).initCompleted { (r, service) in
            // swiftlint:disable force_cast
            let s = service as! AlertServiceImpl
            // swiftlint:enable force_cast
            s.localNotificationsManager = r.resolve(LocalNotificationsManager.self)
        }

        container.register(AppStateService.self) { r in
            let service = AppStateServiceImpl()
            service.settings = r.resolve(RuuviLocalSettings.self)
            service.advertisementDaemon = r.resolve(RuuviTagAdvertisementDaemon.self)
            service.propertiesDaemon = r.resolve(RuuviTagPropertiesDaemon.self)
            service.webTagDaemon = r.resolve(WebTagDaemon.self)
            service.cloudSyncDaemon = r.resolve(RuuviDaemonCloudSync.self)
            service.heartbeatDaemon = r.resolve(RuuviTagHeartbeatDaemon.self)
            service.keychainService = r.resolve(KeychainService.self)
            service.pullWebDaemon = r.resolve(PullWebDaemon.self)
            service.backgroundTaskService = r.resolve(BackgroundTaskService.self)
            service.backgroundProcessService = r.resolve(BackgroundProcessService.self)
            service.userPropertiesService = r.resolve(UserPropertiesService.self)
            service.universalLinkCoordinator = r.resolve(UniversalLinkCoordinator.self)
            return service
        }.inObjectScope(.container)

        container.register(BackgroundProcessService.self) { r in
            if #available(iOS 13, *) {
                let service = BackgroundProcessServiceiOS13()
                service.dataPruningOperationsManager = r.resolve(DataPruningOperationsManager.self)
                return service
            } else {
                let service = BackgroundProcessServiceiOS12()
                service.dataPruningOperationsManager = r.resolve(DataPruningOperationsManager.self)
                return service
            }
        }.inObjectScope(.container)

        container.register(BackgroundTaskService.self) { r in
            if #available(iOS 13, *) {
                let service = BackgroundTaskServiceiOS13()
                service.webTagOperationsManager = r.resolve(WebTagOperationsManager.self)
                return service
            } else {
                let service = BackgroundTaskServiceiOS12()
                return service
            }
        }.inObjectScope(.container)

        container.register(CalibrationService.self) { r in
            let service = CalibrationServiceImpl()
            service.calibrationPersistence = r.resolve(CalibrationPersistence.self)
            return service
        }

        container.register(DataPruningOperationsManager.self) { r in
            let manager = DataPruningOperationsManager()
            manager.settings = r.resolve(RuuviLocalSettings.self)
            manager.ruuviStorage = r.resolve(RuuviStorage.self)
            manager.virtualTagTrunk = r.resolve(VirtualTagTrunk.self)
            manager.virtualTagTank = r.resolve(VirtualTagTank.self)
            manager.ruuviPool = r.resolve(RuuviPool.self)
            return manager
        }

        container.register(ExportService.self) { r in
            let service = ExportServiceTrunk()
            service.ruuviStorage = r.resolve(RuuviStorage.self)
            service.measurementService = r.resolve(MeasurementsService.self)
            service.calibrationService = r.resolve(CalibrationService.self)
            return service
        }

        container.register(FallbackFeatureToggleProvider.self) { _ in
            let provider = FallbackFeatureToggleProvider()
            return provider
        }.inObjectScope(.container)

        container.register(FeatureToggleService.self) { r in
            let service = FeatureToggleService()
            service.firebaseProvider = r.resolve(FirebaseFeatureToggleProvider.self)
            service.fallbackProvider = r.resolve(FallbackFeatureToggleProvider.self)
            service.localProvider = r.resolve(LocalFeatureToggleProvider.self)
            return service
        }.inObjectScope(.container)

        container.register(FirebaseFeatureToggleProvider.self) { r in
            let provider = FirebaseFeatureToggleProvider()
            provider.remoteConfigService = r.resolve(RemoteConfigService.self)
            return provider
        }.inObjectScope(.container)

        container.register(GATTService.self) { r in
            let service = GATTServiceQueue()
            service.ruuviPool = r.resolve(RuuviPool.self)
            service.background = r.resolve(BTBackground.self)
            return service
        }.inObjectScope(.container)

        container.register(LocalFeatureToggleProvider.self) { _ in
            let provider = LocalFeatureToggleProvider()
            return provider
        }.inObjectScope(.container)

        container.register(LocationService.self) { r in
            let service = LocationServiceApple()
            service.locationPersistence = r.resolve(LocationPersistence.self)
            return service
        }

        container.register(MigrationManagerToVIPER.self) { r in
            let manager = MigrationManagerToVIPER()
            manager.sensorService = r.resolve(SensorService.self)
            manager.settings = r.resolve(RuuviLocalSettings.self)
            return manager
        }

        container.register(MigrationManagerToSQLite.self) { r in
            let manager = MigrationManagerToSQLite()
            manager.alertPersistence = r.resolve(AlertPersistence.self)
            manager.calibrationPersistence = r.resolve(CalibrationPersistence.self)
            manager.connectionPersistence = r.resolve(RuuviLocalConnections.self)
            manager.idPersistence = r.resolve(RuuviLocalIDs.self)
            manager.settingsPersistence = r.resolve(RuuviLocalSettings.self)
            manager.realmContext = r.resolve(RealmContext.self)
            manager.sqliteContext = r.resolve(SQLiteContext.self)
            manager.errorPresenter = r.resolve(ErrorPresenter.self)
            manager.ruuviPool = r.resolve(RuuviPool.self)
            return manager
        }

        container.register(MigrationManagerAlertService.self) { r in
            let manager = MigrationManagerAlertService()
            manager.alertService = r.resolve(AlertService.self)
            manager.alertPersistence = r.resolve(AlertPersistence.self)
            manager.realmContext = r.resolve(RealmContext.self)
            manager.ruuviStorage = r.resolve(RuuviStorage.self)
            manager.settings = r.resolve(RuuviLocalSettings.self)
            return manager
        }

        container.register(MigrationManagerToPrune240.self) { r in
            let manager = MigrationManagerToPrune240()
            manager.settings = r.resolve(RuuviLocalSettings.self)
            return manager
        }

        container.register(MigrationManagerToChartDuration240.self) { r in
            let manager = MigrationManagerToChartDuration240()
            manager.settings = r.resolve(RuuviLocalSettings.self)
            return manager
        }

        container.register(MigrationManagerSensorSettings.self) { r in
            let manager = MigrationManagerSensorSettings()
            manager.ruuviStorage = r.resolve(RuuviStorage.self)
            manager.calibrationPersistence = r.resolve(CalibrationPersistence.self)
            manager.errorPresenter = r.resolve(ErrorPresenter.self)
            return manager
        }

        container.register(PullWebDaemon.self) { r in
            let daemon = PullWebDaemonOperations()
            daemon.settings = r.resolve(RuuviLocalSettings.self)
            daemon.webTagOperationsManager = r.resolve(WebTagOperationsManager.self)
            return daemon
        }.inObjectScope(.container)

        container.register(RemoteConfigService.self) { _ in
            let service = FirebaseRemoteConfigService()
            return service
        }.inObjectScope(.container)

        container.register(RuuviDaemonFactory.self) { _ in
            return RuuviDaemonFactoryImpl()
        }

        container.register(RuuviDaemonCloudSync.self) { r in
            let factory = r.resolve(RuuviDaemonFactory.self)!
            let localSettings = r.resolve(RuuviLocalSettings.self)!
            let localSyncState = r.resolve(RuuviLocalSyncState.self)!
            let cloudSyncService = r.resolve(RuuviServiceCloudSync.self)!
            return factory.createCloudSync(
                localSettings: localSettings,
                localSyncState: localSyncState,
                cloudSyncService: cloudSyncService
            )
        }.inObjectScope(.container)

        container.register(RuuviServiceFactory.self) { _ in
            return RuuviServiceFactoryImpl()
        }

        container.register(RuuviServiceCloudSync.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let storage = r.resolve(RuuviStorage.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let pool = r.resolve(RuuviPool.self)!
            let localSettings = r.resolve(RuuviLocalSettings.self)!
            let localSyncState = r.resolve(RuuviLocalSyncState.self)!
            let localImages = r.resolve(RuuviLocalImages.self)!
            return factory.createCloudSync(
                ruuviStorage: storage,
                ruuviCloud: cloud,
                ruuviPool: pool,
                ruuviLocalSettings: localSettings,
                ruuviLocalSyncState: localSyncState,
                ruuviLocalImages: localImages
            )
        }

        container.register(RuuviServiceOwnership.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let pool = r.resolve(RuuviPool.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            return factory.createOwnership(ruuviCloud: cloud, ruuviPool: pool)
        }

        container.register(RuuviTagAdvertisementDaemon.self) { r in
            let daemon = RuuviTagAdvertisementDaemonBTKit()
            daemon.settings = r.resolve(RuuviLocalSettings.self)
            daemon.foreground = r.resolve(BTForeground.self)
            daemon.ruuviPool = r.resolve(RuuviPool.self)
            daemon.ruuviReactor = r.resolve(RuuviReactor.self)
            daemon.ruuviStorage = r.resolve(RuuviStorage.self)
            return daemon
        }.inObjectScope(.container)

        container.register(RuuviTagHeartbeatDaemon.self) { r in
            let daemon = RuuviTagHeartbeatDaemonBTKit()
            daemon.background = r.resolve(BTBackground.self)
            daemon.localNotificationsManager = r.resolve(LocalNotificationsManager.self)
            daemon.connectionPersistence = r.resolve(RuuviLocalConnections.self)
            daemon.ruuviPool = r.resolve(RuuviPool.self)
            daemon.ruuviReactor = r.resolve(RuuviReactor.self)
            daemon.ruuviStorage = r.resolve(RuuviStorage.self)
            daemon.alertService = r.resolve(AlertService.self)
            daemon.settings = r.resolve(RuuviLocalSettings.self)
            daemon.pullWebDaemon = r.resolve(PullWebDaemon.self)
            return daemon
        }.inObjectScope(.container)

        container.register(RuuviTagPropertiesDaemon.self) { r in
            let daemon = RuuviTagPropertiesDaemonBTKit()
            daemon.ruuviReactor = r.resolve(RuuviReactor.self)
            daemon.ruuviPool = r.resolve(RuuviPool.self)
            daemon.foreground = r.resolve(BTForeground.self)
            daemon.idPersistence = r.resolve(RuuviLocalIDs.self)
            daemon.realmPersistence = r.resolve(RuuviPersistence.self, name: "realm")
            daemon.sqiltePersistence = r.resolve(RuuviPersistence.self, name: "sqlite")
            return daemon
        }.inObjectScope(.container)

        container.register(SensorService.self) { r in
            let service = SensorServiceImpl()
            service.ruuviLocalImages = r.resolve(RuuviLocalImages.self)
            service.ruuviNetwork = r.resolve(RuuviNetworkUserApi.self)
            service.ruuviCoreImage = r.resolve(RuuviCoreImage.self)
            return service
        }

        container.register(WeatherProviderService.self) { r in
            let service = WeatherProviderServiceImpl()
            service.owmApi = r.resolve(OpenWeatherMapAPI.self)
            service.locationManager = r.resolve(LocationManager.self)
            service.locationService = r.resolve(LocationService.self)
            return service
        }

        container.register(WebTagDaemon.self) { r in
            let daemon = WebTagDaemonImpl()
            daemon.webTagService = r.resolve(WebTagService.self)
            daemon.settings = r.resolve(RuuviLocalSettings.self)
            daemon.webTagPersistence = r.resolve(WebTagPersistence.self)
            daemon.alertService = r.resolve(AlertService.self)
            return daemon
        }.inObjectScope(.container)

        container.register(WebTagOperationsManager.self) { r in
            let manager = WebTagOperationsManager()
            manager.alertService = r.resolve(AlertService.self)
            manager.weatherProviderService = r.resolve(WeatherProviderService.self)
            manager.webTagPersistence = r.resolve(WebTagPersistence.self)
            return manager
        }

        container.register(WebTagService.self) { r in
            let service = WebTagServiceImpl()
            service.webTagPersistence = r.resolve(WebTagPersistence.self)
            service.weatherProviderService = r.resolve(WeatherProviderService.self)
            return service
        }

        container.register(UserPropertiesService.self) { r in
            let service = UserPropertiesServiceImpl()
            service.ruuviStorage = r.resolve(RuuviStorage.self)
            service.settings = r.resolve(RuuviLocalSettings.self)
            return service
        }

        container.register(UniversalLinkCoordinator.self, factory: { r in
            let coordinator = UniversalLinkCoordinatorImpl()
            let router = UniversalLinkRouterImpl()
            coordinator.keychainService = r.resolve(KeychainService.self)
            coordinator.router = router
            return coordinator
        })
    }
}
