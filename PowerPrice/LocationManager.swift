import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    @Published var userLocation: CLLocation?
    @Published var isAuthorized: Bool = false
    
    let storeCoordinates: [String: [CLLocation]] = [
        "H-E-B": [
            CLLocation(latitude: 25.6315, longitude: -100.2789),
            CLLocation(latitude: 25.5900, longitude: -100.2580)
        ],
        "Walmart": [
            CLLocation(latitude: 25.6111, longitude: -100.2989),
            CLLocation(latitude: 25.6550, longitude: -100.3200)
        ],
        "Soriana": [
            CLLocation(latitude: 25.6421, longitude: -100.2900)
        ]
    ]
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            isAuthorized = true
            manager.startUpdatingLocation()
        } else {
            isAuthorized = false
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        userLocation = locations.last
    }
    
    func distanceTo(storeName: String) -> Double? {

        guard let userLoc = userLocation, let branches = storeCoordinates[storeName] else { return nil }

        let shortestDistance = branches.map { userLoc.distance(from: $0) }.min()
        
        if let minMeters = shortestDistance {
            return minMeters / 1000.0
        }
        
        return nil
    }
}
