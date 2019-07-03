import Foundation

protocol DashboardRouterInput {
    func openMenu(output: MenuModuleOutput)
    func openDiscover()
    func openSettings()
    func openAbout()
    func openRuuviWebsite()
    func openChart(ruuviTag: RuuviTagRealm, type: ChartDataType)
    func openHumidityCalibration(ruuviTag: RuuviTagRealm, lastHumidityValue: Double)
    func openTagSettings(ruuviTag: RuuviTagRealm)
}
