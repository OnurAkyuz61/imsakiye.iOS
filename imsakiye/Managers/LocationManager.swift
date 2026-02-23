//
//  LocationManager.swift
//  İftar & Sahur Timer
//
//  Konum izni ve enlem/boylam yönetimi.
//

import Foundation
import CoreLocation
import Combine
import MapKit

private enum LocationStorage {
    static let latKey = "imsakiye.savedLatitude"
    static let lonKey = "imsakiye.savedLongitude"
    static var defaults: UserDefaults { .standard }

    static func save(latitude: Double, longitude: Double) {
        defaults.set(latitude, forKey: latKey)
        defaults.set(longitude, forKey: lonKey)
    }

    static func restore() -> (lat: Double, lon: Double)? {
        guard defaults.object(forKey: latKey) != nil, defaults.object(forKey: lonKey) != nil else { return nil }
        let lat = defaults.double(forKey: latKey)
        let lon = defaults.double(forKey: lonKey)
        guard lat >= -90, lat <= 90, lon >= -180, lon <= 180 else { return nil }
        return (lat, lon)
    }
}

@MainActor
final class LocationManager: NSObject, ObservableObject {
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var lastLocation: CLLocation?
    @Published var placemark: CLPlacemark?
    /// iOS 26+: reverse geocoding sonucu (placemark yerine; MKAddress kullanımı için).
    @Published var lastMapItem: MKMapItem?
    
    var latitude: Double? { lastLocation?.coordinate.latitude }
    var longitude: Double? { lastLocation?.coordinate.longitude }
    
    var hasValidLocation: Bool {
        guard let lat = latitude, let lon = longitude else { return false }
        return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180
    }
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        manager.distanceFilter = 500
        authorizationStatus = manager.authorizationStatus
        if let loc = manager.location {
            lastLocation = loc
            persistLocation(loc)
        } else if let saved = LocationStorage.restore(),
                  authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            lastLocation = CLLocation(latitude: saved.lat, longitude: saved.lon)
            Task { await updatePlacemark() }
        }
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        manager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }
    
    /// Konum bilgisinden şehir/ilçe adını alır (ters coğrafi kodlama).
    func updatePlacemark() async {
        guard let location = lastLocation else { return }
        if #available(iOS 26.0, *) {
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            do {
                let mapItems = try await request.mapItems
                await MainActor.run {
                    self.lastMapItem = mapItems.first
                    self.placemark = nil
                }
            } catch {
                await MainActor.run {
                    self.lastMapItem = nil
                }
            }
        } else {
            let geocoder = CLGeocoder()
            do {
                let placemarks = try await geocoder.reverseGeocodeLocation(location)
                await MainActor.run {
                    self.lastMapItem = nil
                    self.placemark = placemarks.first
                }
            } catch {
                // Sessizce yoksay; şehir alanı boş kalır
            }
        }
    }
    
    var locationDisplayName: String {
        if #available(iOS 26.0, *), let item = lastMapItem, let addr = item.address {
            return addr.shortAddress ?? addr.fullAddress ?? "—"
        }
        if let locality = placemark?.locality {
            return locality
        }
        if let administrativeArea = placemark?.administrativeArea {
            return administrativeArea
        }
        if let country = placemark?.country {
            return country
        }
        if let lat = latitude, let lon = longitude {
            return String(format: "%.2f, %.2f", lat, lon)
        }
        return "—"
    }
}

extension LocationManager: CLLocationManagerDelegate {
    private func persistLocation(_ location: CLLocation) {
        LocationStorage.save(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                if let loc = manager.location {
                    self.lastLocation = loc
                    self.persistLocation(loc)
                } else if let saved = LocationStorage.restore() {
                    self.lastLocation = CLLocation(latitude: saved.lat, longitude: saved.lon)
                }
                self.manager.startUpdatingLocation()
                await self.updatePlacemark()
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = location
            self.persistLocation(location)
            await self.updatePlacemark()
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // İsteğe bağlı: hata durumunu yayınlayabilirsiniz
    }
}
