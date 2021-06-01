import Foundation
import Future
import RuuviOntology
import RuuviPool
import RuuviCloud
import RuuviLocal
import RuuviCore

final class RuuviServiceSensorPropertiesImpl: RuuviServiceSensorProperties {
    private let pool: RuuviPool
    private let cloud: RuuviCloud
    private let coreImage: RuuviCoreImage
    private let localImages: RuuviLocalImages

    init(
        pool: RuuviPool,
        cloud: RuuviCloud,
        coreImage: RuuviCoreImage,
        localImages: RuuviLocalImages
    ) {
        self.pool = pool
        self.cloud = cloud
        self.coreImage = coreImage
        self.localImages = localImages
    }

    func set(
        name: String,
        for sensor: RuuviTagSensor
    ) -> Future<AnyRuuviTagSensor, RuuviServiceError> {
        let promise = Promise<AnyRuuviTagSensor, RuuviServiceError>()
        if sensor.isOwner {
            let namedSensor = sensor.with(name: name)
            pool.update(namedSensor)
                .on(success: { [weak self] _ in
                    self?.cloud.update(name: name, for: sensor)
                    promise.succeed(value: namedSensor.any)
                }, failure: { error in
                    promise.fail(error: .ruuviPool(error))
                })

        } else {
            let namedSensor = sensor.with(name: name)
            pool.update(namedSensor)
                .on(success: { _ in
                    promise.succeed(value: namedSensor.any)
                }, failure: { error in
                    promise.fail(error: .ruuviPool(error))
                })
        }
        return promise.future
    }

    func set(
        image: UIImage,
        for sensor: VirtualSensor
    ) -> Future<URL, RuuviServiceError> {
        let promise = Promise<URL, RuuviServiceError>()
        localImages.setCustomBackground(
            image: image,
            for: sensor.id.luid
        ).on(success: { url in
            promise.succeed(value: url)
        }, failure: { error in
            promise.fail(error: .ruuviLocal(error))
        })
        return promise.future
    }

    func setNextDefaultBackground(for sensor: VirtualSensor) -> Future<UIImage, RuuviServiceError> {
        let luid = sensor.id.luid
        let macId: MACIdentifier? = nil
        return setNextDefaultBackground(luid: luid, macId: macId)
    }

    func setNextDefaultBackground(for sensor: RuuviTagSensor) -> Future<UIImage, RuuviServiceError> {
        let luid = sensor.luid
        let macId = sensor.macId
        return setNextDefaultBackground(luid: luid, macId: macId)
    }

    func setNextDefaultBackground(luid: LocalIdentifier?, macId: MACIdentifier?) -> Future<UIImage, RuuviServiceError> {
        let promise = Promise<UIImage, RuuviServiceError>()
        let identifier = luid ?? macId
        if let identifier = identifier {
            if let image = localImages.setNextDefaultBackground(for: identifier) {
                promise.succeed(value: image)
            } else {
                promise.fail(error: .failedToFindOrGenerateBackgroundImage)
            }
        } else {
            promise.fail(error: .bothLuidAndMacAreNil)
        }
        return promise.future
    }

    // swiftlint:disable:next function_body_length
    func set(
        image: UIImage,
        for sensor: RuuviTagSensor,
        progress: ((MACIdentifier, Double) -> Void)?,
        maxSize: CGSize
    ) -> Future<URL, RuuviServiceError> {
        let promise = Promise<URL, RuuviServiceError>()
        guard let jpegData = image.jpegData(compressionQuality: 1.0) else {
            promise.fail(error: .failedToGetJpegRepresentation)
            return promise.future
        }
        let luid = sensor.luid
        let macId = sensor.macId
        assert(luid != nil || macId != nil)
        var local: Future<URL, RuuviLocalError>?
        var remote: Future<URL, RuuviCloudError>?
        if sensor.isClaimed {
            if let mac = macId {
                let croppedImage = coreImage.cropped(image: image, to: maxSize)
                remote = cloud.upload(
                    imageData: jpegData,
                    mimeType: .jpg,
                    progress: { macId, percentage in
                        self.localImages.setBackgroundUploadProgress(
                            percentage: percentage,
                            for: macId
                        )
                        progress?(macId, percentage)
                    },
                    for: mac
                )
                local = localImages.setCustomBackground(image: image, for: mac)
            } else if let luid = luid {
                local = localImages.setCustomBackground(image: image, for: luid)
            } else {
                promise.fail(error: .bothLuidAndMacAreNil)
                return promise.future
            }
        } else {
            if let mac = macId {
                local = localImages.setCustomBackground(image: image, for: mac)
            } else if let luid = luid {
                local = localImages.setCustomBackground(image: image, for: luid)
            } else {
                promise.fail(error: .bothLuidAndMacAreNil)
                return promise.future
            }
        }

        if let local = local, let remote = remote {
            if let mac = macId {
                localImages.setBackgroundUploadProgress(percentage: 0.0, for: mac)
            }
            remote.on(success: {_ in
                local.on(success: { localUrl in
                    if let mac = macId {
                        self.localImages.deleteBackgroundUploadProgress(for: mac)
                    }
                    promise.succeed(value: localUrl)
                }, failure: { error in
                    promise.fail(error: .ruuviLocal(error))
                })
            }, failure: { error in
                promise.fail(error: .ruuviCloud(error))
            })
        } else if let local = local {
            local.on(success: { url in
                promise.succeed(value: url)
            }, failure: { error in
                promise.fail(error: .ruuviLocal(error))
            })
        } else {
            promise.fail(error: .bothLuidAndMacAreNil)
            return promise.future
        }
        return promise.future
    }

    func getImage(for sensor: VirtualSensor) -> Future<UIImage, RuuviServiceError> {
        let luid = sensor.id.luid
        let macId: MACIdentifier? = nil
        return getImage(luid: luid, macId: macId)
    }

    func getImage(for sensor: RuuviTagSensor) -> Future<UIImage, RuuviServiceError> {
        return getImage(luid: sensor.luid, macId: sensor.macId)
    }

    func removeImage(for sensor: RuuviTagSensor) {
        if let macId = sensor.macId {
            localImages.deleteCustomBackground(for: macId)
        }
        if let luid = sensor.luid {
            localImages.deleteCustomBackground(for: luid)
        }
    }

    func removeImage(for sensor: VirtualSensor) {
        localImages.deleteCustomBackground(for: sensor.id.luid)
    }

    private func getImage(luid: LocalIdentifier?, macId: MACIdentifier?) -> Future<UIImage, RuuviServiceError> {
        let promise = Promise<UIImage, RuuviServiceError>()
        if let macId = macId {
            if let image = localImages.background(for: macId) {
                promise.succeed(value: image)
            } else if let luid = luid, let image = localImages.background(for: luid) {
                promise.succeed(value: image)
            } else {
                promise.fail(error: .failedToFindOrGenerateBackgroundImage)
            }
        } else if let luid = luid {
            if let image = localImages.background(for: luid) {
                promise.succeed(value: image)
            } else {
                promise.fail(error: .failedToFindOrGenerateBackgroundImage)
            }
        } else {
            promise.fail(error: .bothLuidAndMacAreNil)
        }
        return promise.future
    }
}
