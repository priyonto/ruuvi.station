import Foundation
import CoreLocation
import Future

protocol LocationManager {
    var isLocationPermissionGranted: Bool { get }
    var locationAuthorizationStatus: CLAuthorizationStatus { get }
    func requestLocationPermission(completion: ((Bool) -> Void)?)
    func getCurrentLocation() -> Future<CLLocation, RUError>
}
