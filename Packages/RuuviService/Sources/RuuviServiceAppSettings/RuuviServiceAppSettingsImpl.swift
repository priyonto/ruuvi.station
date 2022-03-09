import Foundation
import Future
import RuuviOntology
import RuuviCloud
import RuuviLocal
import RuuviService

public final class RuuviServiceAppSettingsImpl: RuuviServiceAppSettings {
    private let cloud: RuuviCloud
    private var localSettings: RuuviLocalSettings

    public init(
        cloud: RuuviCloud,
        localSettings: RuuviLocalSettings
    ) {
        self.cloud = cloud
        self.localSettings = localSettings
    }

    @discardableResult
    public func set(temperatureUnit: TemperatureUnit) -> Future<TemperatureUnit, RuuviServiceError> {
        let promise = Promise<TemperatureUnit, RuuviServiceError>()
        localSettings.temperatureUnit = temperatureUnit
        cloud.set(temperatureUnit: temperatureUnit)
            .on(success: { temperatureUnit in
                promise.succeed(value: temperatureUnit)
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        return promise.future
    }

    @discardableResult
    public func set(humidityUnit: HumidityUnit) -> Future<HumidityUnit, RuuviServiceError> {
        let promise = Promise<HumidityUnit, RuuviServiceError>()
        localSettings.humidityUnit = humidityUnit
        cloud.set(humidityUnit: humidityUnit)
            .on(success: { humidityUnit in
                promise.succeed(value: humidityUnit)
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        return promise.future
    }

    @discardableResult
    public func set(pressureUnit: UnitPressure) -> Future<UnitPressure, RuuviServiceError> {
        let promise = Promise<UnitPressure, RuuviServiceError>()
        localSettings.pressureUnit = pressureUnit
        cloud.set(pressureUnit: pressureUnit)
            .on(success: { pressureUnit in
                promise.succeed(value: pressureUnit)
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        return promise.future
    }

    @discardableResult
    public func set(showAllData: Bool) -> Future<Bool, RuuviServiceError> {
        let promise = Promise<Bool, RuuviServiceError>()
        cloud.set(showAllData: showAllData)
            .on(success: { showAllData in
                promise.succeed(value: showAllData)
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        return promise.future
    }

    @discardableResult
    public func set(drawDots: Bool) -> Future<Bool, RuuviServiceError> {
        let promise = Promise<Bool, RuuviServiceError>()
        cloud.set(drawDots: drawDots)
            .on(success: { drawDots in
                promise.succeed(value: drawDots)
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        return promise.future
    }

    @discardableResult
    public func set(chartDuration: Int) -> Future<Int, RuuviServiceError> {
        let promise = Promise<Int, RuuviServiceError>()
        cloud.set(chartDuration: chartDuration)
            .on(success: { chartDuration in
                promise.succeed(value: chartDuration)
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        return promise.future
    }
}
