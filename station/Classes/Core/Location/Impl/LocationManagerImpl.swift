import Foundation

import Foundation
import CoreLocation

class LocationManagerImpl: NSObject, LocationManager {
    
    var isLocationPermissionGranted: Bool {
        get {
            return CLLocationManager.locationServicesEnabled()
                && (CLLocationManager.authorizationStatus() == .authorizedWhenInUse || CLLocationManager.authorizationStatus() == .authorizedAlways)
        }
    }
    
    private var locationManager: CLLocationManager
    private var requestLocationPermissionCallback: ((Bool) -> Void)?
    private var getCurrentLocationCallback: ((CLLocation?) -> Void)?
    
    override init() {
        locationManager = CLLocationManager()
        super.init()
        locationManager.delegate = self
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
    }
    
    func requestLocationPermission(completion: ((Bool) -> Void)?) {
        if isLocationPermissionGranted {
            completion?(true)
        } else {
            requestLocationPermissionCallback = completion
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func getCurrentLocation(completion: ((CLLocation?) -> Void)?) {
        getCurrentLocationCallback = completion
        locationManager.startUpdatingLocation()
    }
}

extension LocationManagerImpl: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        requestLocationPermissionCallback?(status == .authorizedWhenInUse || status == .authorizedAlways)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locationManager.stopUpdatingLocation()
        getCurrentLocationCallback?(locations.last)
    }
    
}
