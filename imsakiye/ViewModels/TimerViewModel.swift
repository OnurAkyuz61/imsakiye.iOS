//
//  TimerViewModel.swift
//  İftar & Sahur Timer
//
//  MVVM: Ana ekran state'i, konum, API ve geri sayım mantığı.
//

import Foundation
import Combine
import CoreLocation

@MainActor
final class TimerViewModel: ObservableObject {
    // MARK: - Published State
    
    @Published var prayerDay: PrayerDay?
    @Published var countdownSeconds: TimeInterval = 0
    @Published var isCountingToIftar: Bool = true
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    /// Cihaz konumu mu yoksa manuel seçilen şehir mi kullanılıyor?
    @Published var useDeviceLocation: Bool = true
    /// Manuel seçilen yer (Ayarlar'dan şehir arama ile set edilir).
    @Published var manualPlace: (name: String, lat: Double, lon: Double)?
    
    // MARK: - Sun/Moon arc (0...1: İmsak→Maghrib veya Maghrib→İmsak)
    
    /// Gündüz veya gece yayı üzerindeki ilerleme (0...1)
    @Published var celestialProgress: Double = 0
    
    // MARK: - Dependencies
    
    private let locationManager: LocationManager
    private let networkManager: NetworkManager
    private var timerTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    init(locationManager: LocationManager, networkManager: NetworkManager = NetworkManager.shared) {
        self.locationManager = locationManager
        self.networkManager = networkManager
        bindLocation()
        startCountdownTimer()
    }
    
    private func bindLocation() {
        // Cihaz konumu değiştiğinde sadece useDeviceLocation true ise güncelle
        locationManager.$placemark
            .combineLatest($useDeviceLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, useDevice in
                guard useDevice else { return }
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        locationManager.$lastLocation
            .combineLatest($useDeviceLocation)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, useDevice in
                guard useDevice else { return }
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
    
    /// Gösterilecek konum adı (cihaz veya manuel seçilen şehir).
    var locationDisplayName: String {
        if useDeviceLocation {
            return locationManager.locationDisplayName
        }
        return manualPlace?.name ?? "—"
    }
    
    /// Anlık konumu kullan; manuel yeri temizle ve vakitleri yeniden çek.
    func useCurrentLocation() {
        useDeviceLocation = true
        manualPlace = nil
        requestLocationAndFetchPrayerTimes()
    }
    
    /// Manuel yer seçildi (Ayarlar'dan şehir arama). Vakitleri bu koordinata göre çeker.
    func setManualPlace(name: String, lat: Double, lon: Double) {
        useDeviceLocation = false
        manualPlace = (name: name, lat: lat, lon: lon)
        fetchPrayerTimesIfPossible()
    }
    
    func requestLocationAndFetchPrayerTimes() {
        if useDeviceLocation {
            locationManager.requestPermission()
            locationManager.startUpdatingLocation()
        }
        fetchPrayerTimesIfPossible()
    }
    
    func fetchPrayerTimesIfPossible() {
        let lat: Double
        let lon: Double
        if useDeviceLocation {
            guard locationManager.hasValidLocation,
                  let la = locationManager.latitude,
                  let lo = locationManager.longitude else {
                errorMessage = "Konum alınamadı. Lütfen konum iznini verin veya Ayarlar'dan şehir seçin."
                return
            }
            lat = la
            lon = lo
        } else if let place = manualPlace {
            lat = place.lat
            lon = place.lon
        } else {
            errorMessage = "Konum seçin: Ayarlar'dan şehir arayın veya anlık konumu kullanın."
            return
        }
        errorMessage = nil
        isLoading = true
        Task {
            do {
                let day = try await networkManager.fetchPrayerTimes(latitude: lat, longitude: lon, date: Date())
                prayerDay = day
                if useDeviceLocation {
                    await locationManager.updatePlacemark()
                }
                updateCountdownAndProgress()
            } catch {
                errorMessage = "Vakitler yüklenemedi. İnternet bağlantınızı kontrol edin."
            }
            isLoading = false
        }
    }
    
    private func startCountdownTimer() {
        timerTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                await MainActor.run {
                    self?.updateCountdownAndProgress()
                }
            }
        }
    }
    
    private func updateCountdownAndProgress() {
        let now = Date()
        guard let day = prayerDay else {
            countdownSeconds = 0
            celestialProgress = 0
            return
        }
        let imsakTime = day.imsak
        let aksamTime = day.maghrib
        
        // 1. now < imsakTime → Hedef: Bugünün İmsak. Başlık: "Sahura Kalan Süre"
        if now < imsakTime {
            isCountingToIftar = false
            countdownSeconds = max(0, imsakTime.timeIntervalSince(now))
            celestialProgress = day.nightProgressBeforeImsak(now: now)
        }
        // 2. imsakTime <= now < aksamTime → Hedef: Bugünün Akşam. Başlık: "İftara Kalan Süre"
        else if now >= imsakTime && now < aksamTime {
            isCountingToIftar = true
            countdownSeconds = max(0, aksamTime.timeIntervalSince(now))
            celestialProgress = day.dayProgress(now: now)
        }
        // 3. now >= aksamTime → Hedef: Yarının İmsak. Başlık: "Sahura Kalan Süre"
        else {
            isCountingToIftar = false
            if let nextImsak = day.nextImsak {
                countdownSeconds = max(0, nextImsak.timeIntervalSince(now))
                celestialProgress = day.nightProgress(now: now)
            } else {
                countdownSeconds = 0
                celestialProgress = 1
            }
        }
    }
    
    /// İftar sayacı mı gösteriliyor?
    var isIftarCountdown: Bool { isCountingToIftar }
    
    /// Geri sayım metni (HH:mm:ss)
    var countdownText: String {
        Date.countdownString(from: countdownSeconds)
    }
    
    /// Bugünkü İmsak saati metni
    var imsakTimeText: String {
        prayerDay?.imsak.prayerTimeString ?? "—:—"
    }
    
    /// Bugünkü Akşam/İftar saati metni
    var maghribTimeText: String {
        prayerDay?.maghrib.prayerTimeString ?? "—:—"
    }
    
    /// Gündüz mü (Güneş göstermek için). İmsak–Akşam arası true.
    var isDaytime: Bool {
        guard let day = prayerDay else { return true }
        let now = Date()
        return now >= day.imsak && now < day.maghrib
    }
    
    deinit {
        timerTask?.cancel()
    }
}
