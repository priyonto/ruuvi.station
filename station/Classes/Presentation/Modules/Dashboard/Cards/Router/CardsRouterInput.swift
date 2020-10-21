import Foundation

protocol CardsRouterInput {
    func openMenu(output: MenuModuleOutput)
    func openDiscover(output: DiscoverModuleOutput)
    func openSettings()
    func openAbout()
    func openRuuviWebsite()
    func openSignIn(output: SignInModuleOutput)
    func openTagsManager(output: TagsManagerModuleOutput)
    func openTagSettings(ruuviTag: RuuviTagSensor,
                         temperature: Temperature?,
                         humidity: Humidity?,
                         output: TagSettingsModuleOutput)
    func openWebTagSettings(webTag: WebTagRealm,
                            temperature: Temperature?)
    func openTagCharts()
}
