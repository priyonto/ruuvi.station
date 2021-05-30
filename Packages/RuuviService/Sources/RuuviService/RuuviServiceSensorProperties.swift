import Foundation
import Future
import RuuviOntology

public protocol RuuviServiceSensorProperties {
    @discardableResult
    func set(
        name: String,
        for sensor: RuuviTagSensor
    ) -> Future<AnyRuuviTagSensor, RuuviServiceError>

    @discardableResult
    func set(
        image: UIImage,
        for sensor: RuuviTagSensor,
        progress: ((MACIdentifier, Double) -> Void)?,
        maxSize: CGSize
    ) -> Future<URL, RuuviServiceError>

    func getImage(for sensor: RuuviTagSensor) -> Future<UIImage, RuuviServiceError>

    func getImage(for sensor: VirtualSensor) -> Future<UIImage, RuuviServiceError>
}

extension RuuviServiceSensorProperties {
    public func set(
        image: UIImage,
        for sensor: RuuviTagSensor
    ) -> Future<URL, RuuviServiceError> {
        return set(
            image: image,
            for: sensor,
            progress: nil,
            maxSize: CGSize(width: 1080, height: 1920)
        )
    }
}
