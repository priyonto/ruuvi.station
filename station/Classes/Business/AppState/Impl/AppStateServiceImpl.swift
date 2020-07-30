import UIKit

class AppStateServiceImpl: AppStateService {

    var settings: Settings!
    var advertisementDaemon: RuuviTagAdvertisementDaemon!
    var propertiesDaemon: RuuviTagPropertiesDaemon!
    var webTagDaemon: WebTagDaemon!
    var heartbeatDaemon: RuuviTagHeartbeatDaemon!
    var pullWebDaemon: PullWebDaemon!
    var backgroundTaskService: BackgroundTaskService!
    var backgroundProcessService: BackgroundProcessService!

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) {
        if settings.isAdvertisementDaemonOn {
            advertisementDaemon.start()
        }
        if settings.isWebTagDaemonOn {
            webTagDaemon.start()
        }
        heartbeatDaemon.start()
        propertiesDaemon.start()
        pullWebDaemon.start()
        backgroundTaskService.register()
        backgroundProcessService.register()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // do nothing yet
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // do nothing yet
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        if settings.isAdvertisementDaemonOn {
            advertisementDaemon.stop()
        }
        if settings.isWebTagDaemonOn {
            webTagDaemon.stop()
        }
        propertiesDaemon.stop()
        pullWebDaemon.stop()
        backgroundTaskService.schedule()
        backgroundProcessService.schedule()
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        if settings.isAdvertisementDaemonOn {
            advertisementDaemon.start()
        }
        if settings.isWebTagDaemonOn {
            webTagDaemon.start()
        }
        propertiesDaemon.start()
        pullWebDaemon.start()
        backgroundProcessService.launch()
    }
}
