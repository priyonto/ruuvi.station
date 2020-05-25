import Foundation

protocol SettingsRouterInput {
    func dismiss()
    func openLanguage()
    func openForeground()
    func openDefaults()
    func openHeartbeat()
    func openAdvanced()
}
