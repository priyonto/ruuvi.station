import Foundation
import Future
import CoreLocation

class WebTagServiceImpl: WebTagService {
    
    var webTagPersistence: WebTagPersistence!
    var weatherProviderService: WeatherProviderService!
    
    func add(provider: WeatherProvider, location: Location) -> Future<WeatherProvider,RUError> {
        return webTagPersistence.persist(provider: provider, location: location)
    }
    
    func add(provider: WeatherProvider) -> Future<WeatherProvider,RUError> {
        return webTagPersistence.persist(provider: provider)
    }
    
    func remove(webTag: WebTagRealm) -> Future<Bool,RUError> {
        return webTagPersistence.remove(webTag: webTag)
    }
    
    func update(name: String, of webTag: WebTagRealm) -> Future<Bool,RUError> {
        return webTagPersistence.update(name: name, of: webTag)
    }
    
    func update(location: Location, of webTag: WebTagRealm) -> Future<Bool,RUError> {
        return webTagPersistence.update(location: location, of: webTag)
    }
    
    func clearLocation(of webTag: WebTagRealm) -> Future<Bool,RUError> {
        return webTagPersistence.clearLocation(of: webTag)
    }

    @discardableResult
    func observeCurrentLocationData<T: AnyObject>(_ observer: T, provider: WeatherProvider, interval: TimeInterval, closure: @escaping (T, WPSData?, Location?, RUError?) -> Void) -> RUObservationToken {
        return weatherProviderService.observeCurrentLocationData(observer, provider: provider, interval: interval, closure: { [weak self] (observer, data, location, error) in
            if let data = data {
                self?.webTagPersistence.persistCurrentLocation(data: data)
            }
            closure(observer, data, location, error)
        })
    }
    
    @discardableResult
    func observeData<T: AnyObject>(_ observer: T, coordinate: CLLocationCoordinate2D, provider: WeatherProvider, interval: TimeInterval, closure: @escaping (T, WPSData?, RUError?) -> Void) -> RUObservationToken {
        return weatherProviderService.observeData(observer, coordinate: coordinate, provider: provider, interval: interval, closure: { [weak self] (observer, data, error) in
            if let data = data {
                self?.webTagPersistence.persist(coordinate: coordinate, data: data)
            }
            closure(observer, data, error)
        })
    }
}
