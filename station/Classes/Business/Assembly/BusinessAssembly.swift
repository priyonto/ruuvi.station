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
import RuuviRepository
import RuuviUser
import RuuviVirtual
import RuuviLocation
import RuuviNotification
import RuuviNotifier
#if canImport(RuuviServiceGATT)
import RuuviServiceGATT
#endif
#if canImport(RuuviAnalytics)
import RuuviAnalytics
#endif
#if canImport(RuuviAnalyticsImpl)
import RuuviAnalyticsImpl
#endif
#if canImport(RuuviServiceExport)
import RuuviServiceExport
#endif
#if canImport(RuuviNotifierImpl)
import RuuviNotifierImpl
#endif
#if canImport(RuuviServiceFactory)
import RuuviServiceFactory
#endif
#if canImport(RuuviDaemonCloudSync)
import RuuviDaemonCloudSync
#endif
#if canImport(RuuviRepositoryCoordinator)
import RuuviRepositoryCoordinator
#endif
#if canImport(RuuviUserCoordinator)
import RuuviUserCoordinator
#endif
#if canImport(RuuviCoreLocation)
import RuuviCoreLocation
#endif
#if canImport(RuuviLocationService)
import RuuviLocationService
#endif
#if canImport(RuuviVirtualOWM)
import RuuviVirtualOWM
#endif
#if canImport(RuuviVirtualService)
import RuuviVirtualService
#endif

// swiftlint:disable:next type_body_length
class BusinessAssembly: Assembly {
    // swiftlint:disable:next function_body_length
    func assemble(container: Container) {
        container.register(RuuviNotifier.self) { r in
            let notificationLocal = r.resolve(RuuviNotificationLocal.self)!
            let ruuviAlertService = r.resolve(RuuviServiceAlert.self)!
            let titles = RuuviNotifierTitlesImpl()
            let service = RuuviNotifierImpl(
                ruuviAlertService: ruuviAlertService,
                ruuviNotificationLocal: notificationLocal,
                titles: titles
            )
            return service
        }.inObjectScope(.container)

        container.register(AppStateService.self) { r in
            let service = AppStateServiceImpl()
            service.settings = r.resolve(RuuviLocalSettings.self)
            service.advertisementDaemon = r.resolve(RuuviTagAdvertisementDaemon.self)
            service.propertiesDaemon = r.resolve(RuuviTagPropertiesDaemon.self)
            service.webTagDaemon = r.resolve(VirtualTagDaemon.self)
            service.cloudSyncDaemon = r.resolve(RuuviDaemonCloudSync.self)
            service.heartbeatDaemon = r.resolve(RuuviTagHeartbeatDaemon.self)
            service.ruuviUser = r.resolve(RuuviUser.self)
            service.pullWebDaemon = r.resolve(PullWebDaemon.self)
            service.backgroundTaskService = r.resolve(BackgroundTaskService.self)
            service.backgroundProcessService = r.resolve(BackgroundProcessService.self)
            #if canImport(RuuviAnalytics)
            service.userPropertiesService = r.resolve(RuuviAnalytics.self)
            #endif
            service.universalLinkCoordinator = r.resolve(UniversalLinkCoordinator.self)
            return service
        }.inObjectScope(.container)

        container.register(RuuviServiceExport.self) { r in
            let ruuviStorage = r.resolve(RuuviStorage.self)!
            let measurementService = r.resolve(RuuviServiceMeasurement.self)!
            let service = RuuviServiceExportImpl(
                ruuviStorage: ruuviStorage,
                measurementService: measurementService,
                headersProvider: ExportHeadersProvider(),
                emptyValueString: "N/A".localized()
            )
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
            let ruuviPool = r.resolve(RuuviPool.self)!
            let background = r.resolve(BTBackground.self)!
            let service = GATTServiceQueue(
                ruuviPool: ruuviPool,
                background: background
            )
            return service
        }.inObjectScope(.container)

        container.register(LocalFeatureToggleProvider.self) { _ in
            let provider = LocalFeatureToggleProvider()
            return provider
        }.inObjectScope(.container)

        container.register(RuuviLocationService.self) { _ in
            let service = RuuviLocationServiceApple()
            return service
        }

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

        container.register(RuuviRepositoryFactory.self) { _ in
            return RuuviRepositoryFactoryCoordinator()
        }

        container.register(RuuviRepository.self) { r in
            let factory = r.resolve(RuuviRepositoryFactory.self)!
            let pool = r.resolve(RuuviPool.self)!
            let storage = r.resolve(RuuviStorage.self)!
            return factory.create(
                pool: pool,
                storage: storage
            )
        }

        container.register(RuuviServiceFactory.self) { _ in
            return RuuviServiceFactoryImpl()
        }

        container.register(RuuviServiceAlert.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let localIDs = r.resolve(RuuviLocalIDs.self)!
            return factory.createAlert(
                ruuviCloud: cloud,
                ruuviLocalIDs: localIDs
            )
        }

        container.register(RuuviServiceOffsetCalibration.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let pool = r.resolve(RuuviPool.self)!
            return factory.createOffsetCalibration(
                ruuviCloud: cloud,
                ruuviPool: pool
            )
        }

        container.register(RuuviServiceAppSettings.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let localSettings = r.resolve(RuuviLocalSettings.self)!
            return factory.createAppSettings(
                ruuviCloud: cloud,
                ruuviLocalSettings: localSettings
            )
        }

        container.register(RuuviServiceCloudSync.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let storage = r.resolve(RuuviStorage.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let pool = r.resolve(RuuviPool.self)!
            let localSettings = r.resolve(RuuviLocalSettings.self)!
            let localSyncState = r.resolve(RuuviLocalSyncState.self)!
            let localImages = r.resolve(RuuviLocalImages.self)!
            let repository = r.resolve(RuuviRepository.self)!
            let localIDs = r.resolve(RuuviLocalIDs.self)!
            let alertService = r.resolve(RuuviServiceAlert.self)!
            return factory.createCloudSync(
                ruuviStorage: storage,
                ruuviCloud: cloud,
                ruuviPool: pool,
                ruuviLocalSettings: localSettings,
                ruuviLocalSyncState: localSyncState,
                ruuviLocalImages: localImages,
                ruuviRepository: repository,
                ruuviLocalIDs: localIDs,
                ruuviAlertService: alertService
            )
        }

        container.register(RuuviServiceOwnership.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let pool = r.resolve(RuuviPool.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let propertiesService = r.resolve(RuuviServiceSensorProperties.self)!
            let localIDs = r.resolve(RuuviLocalIDs.self)!
            return factory.createOwnership(
                ruuviCloud: cloud,
                ruuviPool: pool,
                propertiesService: propertiesService,
                localIDs: localIDs
            )
        }

        container.register(RuuviServiceSensorProperties.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let pool = r.resolve(RuuviPool.self)!
            let cloud = r.resolve(RuuviCloud.self)!
            let coreImage = r.resolve(RuuviCoreImage.self)!
            let localImages = r.resolve(RuuviLocalImages.self)!
            return factory.createSensorProperties(
                ruuviPool: pool,
                ruuviCloud: cloud,
                ruuviCoreImage: coreImage,
                ruuviLocalImages: localImages
            )
        }

        container.register(RuuviServiceSensorRecords.self) { r in
            let factory = r.resolve(RuuviServiceFactory.self)!
            let pool = r.resolve(RuuviPool.self)!
            let syncState = r.resolve(RuuviLocalSyncState.self)!
            return factory.createSensorRecords(
                ruuviPool: pool,
                ruuviLocalSyncState: syncState
            )
        }

        container.register(RuuviUserFactory.self) { _ in
            return RuuviUserFactoryCoordinator()
        }

        container.register(RuuviUser.self) { r in
            let factory = r.resolve(RuuviUserFactory.self)!
            return factory.createUser()
        }.inObjectScope(.container)

        container.register(VirtualProviderService.self) { r in
            let owmApi = r.resolve(OpenWeatherMapAPI.self)!
            let locationManager = r.resolve(RuuviCoreLocation.self)!
            let locationService = r.resolve(RuuviLocationService.self)!
            let service = VirtualProviderServiceImpl(
                owmApi: owmApi,
                ruuviCoreLocation: locationManager,
                ruuviLocationService: locationService
            )
            return service
        }

        container.register(VirtualService.self) { r in
            let virtualPersistence = r.resolve(VirtualPersistence.self)!
            let weatherProviderService = r.resolve(VirtualProviderService.self)!
            let ruuviLocalImages = r.resolve(RuuviLocalImages.self)!
            let service = VirtualServiceImpl(
                ruuviLocalImages: ruuviLocalImages,
                virtualPersistence: virtualPersistence,
                virtualProviderService: weatherProviderService
            )
            return service
        }
        #if canImport(RuuviAnalytics)
        container.register(RuuviAnalytics.self) { r in
            let ruuviStorage = r.resolve(RuuviStorage.self)!
            let settings = r.resolve(RuuviLocalSettings.self)!
            let service = RuuviAnalyticsImpl(
                ruuviStorage: ruuviStorage,
                settings: settings
            )
            return service
        }
        #endif
        container.register(UniversalLinkCoordinator.self, factory: { r in
            let coordinator = UniversalLinkCoordinatorImpl()
            let router = UniversalLinkRouterImpl()
            coordinator.ruuviUser = r.resolve(RuuviUser.self)
            coordinator.router = router
            return coordinator
        })
    }
}
