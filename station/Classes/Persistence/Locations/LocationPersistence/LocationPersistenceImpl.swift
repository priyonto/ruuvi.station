import Foundation
import CoreLocation

fileprivate extension Location {
    var asClass: LocationAppleClass {
        return LocationAppleClass(location: self)
    }
}

class LocationPersistenceImpl: LocationPersistence {

    private let regionsKey: String = "LocationPersistence.regions"
    private let regionKey: String = "LocationPersistence.region."

    func locations(for coordinate: CLLocationCoordinate2D) -> [Location]? {
        guard let region = regions.first(where: {$0.contains(coordinate)}) else {
            return nil
        }
        let key = regionKey + region.identifier
        guard let data = UserDefaults.standard.data(forKey: key),
            let locations = NSKeyedUnarchiver.unarchiveObject(with: data) as? [LocationAppleClass] else {
            return nil
        }
        return locations.map({$0.asStruct})
    }

    func setLocations(_ locations: [Location], for coordinate: CLLocationCoordinate2D) {
        let region: CLCircularRegion
        if let existedRegion = regions.first(where: {$0.contains(coordinate)}) {
            region = existedRegion
        } else {
            region = CLCircularRegion(center: coordinate, radius: 1000.0, identifier: UUID().uuidString)
            regions.append(region)
        }
        let key = regionKey + region.identifier
        let array = NSArray(array: locations.map({$0.asClass}))
        let data = NSKeyedArchiver.archivedData(withRootObject: array)
        UserDefaults.standard.set(data, forKey: key)
    }
}
// MARK: - Private
extension LocationPersistenceImpl {
    private var regions: [CLCircularRegion] {
        get {
            guard let data = UserDefaults.standard.data(forKey: regionsKey),
                let regionsPersisted = NSKeyedUnarchiver.unarchiveObject(with: data) as? [CLCircularRegion] else {
                return []
            }
            return regionsPersisted
        }
        set {
            let data = NSKeyedArchiver.archivedData(withRootObject: newValue)
            UserDefaults.standard.set(data, forKey: regionsKey)
        }
    }
}
