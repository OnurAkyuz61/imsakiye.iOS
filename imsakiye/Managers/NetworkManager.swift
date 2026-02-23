//
//  NetworkManager.swift
//  İftar & Sahur Timer
//
//  Aladhan API ile namaz vakitleri çekme.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case noData
    case decoding(Error)
    case server(Int)
    case other(Error)
}

actor NetworkManager {
    static let shared = NetworkManager()
    
    private let baseURL = "https://api.aladhan.com/v1"
    private let session: URLSession
    
    private init(session: URLSession = .shared) {
        self.session = session
    }
    
    /// Verilen enlem/boylam ve tarih için namaz vakitlerini getirir.
    /// - Parameters:
    ///   - latitude: Enlem
    ///   - longitude: Boylam
    ///   - date: İstenen gün (varsayılan: bugün)
    /// - Returns: O güne ait PrayerDay (İmsak, Maghrib; ertesi gün İmsak için ayrı çağrı gerekebilir)
    func fetchPrayerTimes(latitude: Double, longitude: Double, date: Date = Date()) async throws -> PrayerDay {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: date)
        let month = calendar.component(.month, from: date)
        let year = calendar.component(.year, from: date)
        // API: timingsByDate veya timings?date=DD-MM-YYYY
        let dateString = String(format: "%02d-%02d-%04d", day, month, year)
        guard let url = URL(string: "\(baseURL)/timings/\(dateString)?latitude=\(latitude)&longitude=\(longitude)") else {
            throw NetworkError.invalidURL
        }
        
        let (data, response) = try await session.data(from: url)
        
        guard let http = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        guard (200...299).contains(http.statusCode) else {
            throw NetworkError.server(http.statusCode)
        }
        
        let decoded: AladhanAPIResponse
        do {
            decoded = try await Task.detached(priority: .userInitiated) {
                try JSONDecoder().decode(AladhanAPIResponse.self, from: data)
            }.value
        } catch {
            throw NetworkError.decoding(error)
        }
        
        let timings = decoded.data.timings
        let timezone = decoded.data.meta?.timezone ?? TimeZone.current.identifier
        
        guard let imsak = Self.parseTime(timings.Imsak, for: date, timeZoneIdentifier: timezone),
              let maghrib = Self.parseTime(timings.Maghrib, for: date, timeZoneIdentifier: timezone) else {
            throw NetworkError.decoding(NSError(domain: "PrayerTimes", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid time format"]))
        }
        
        // Ertesi günün İmsak'ı (Sahur sayacı için)
        let nextDay = calendar.date(byAdding: .day, value: 1, to: date) ?? date
        let nextDateString = String(format: "%02d-%02d-%04d",
                                    calendar.component(.day, from: nextDay),
                                    calendar.component(.month, from: nextDay),
                                    calendar.component(.year, from: nextDay))
        var nextImsak: Date?
        var nextMaghrib: Date?
        if let nextURL = URL(string: "\(baseURL)/timings/\(nextDateString)?latitude=\(latitude)&longitude=\(longitude)") {
            if let (nextData, _) = try? await session.data(from: nextURL),
               let nextDecoded = try? await Task.detached(priority: .userInitiated) { try JSONDecoder().decode(AladhanAPIResponse.self, from: nextData) }.value {
                nextImsak = Self.parseTime(nextDecoded.data.timings.Imsak, for: nextDay, timeZoneIdentifier: timezone)
                nextMaghrib = Self.parseTime(nextDecoded.data.timings.Maghrib, for: nextDay, timeZoneIdentifier: timezone)
            }
        }
        
        // Önceki günün Akşam'ı (gece yarısından imsaka progress için)
        let previousDay = calendar.date(byAdding: .day, value: -1, to: date) ?? date
        let prevDateString = String(format: "%02d-%02d-%04d",
                                    calendar.component(.day, from: previousDay),
                                    calendar.component(.month, from: previousDay),
                                    calendar.component(.year, from: previousDay))
        var previousMaghrib: Date?
        if let prevURL = URL(string: "\(baseURL)/timings/\(prevDateString)?latitude=\(latitude)&longitude=\(longitude)") {
            if let (prevData, _) = try? await session.data(from: prevURL),
               let prevDecoded = try? await Task.detached(priority: .userInitiated) { try JSONDecoder().decode(AladhanAPIResponse.self, from: prevData) }.value,
               let prev = Self.parseTime(prevDecoded.data.timings.Maghrib, for: previousDay, timeZoneIdentifier: timezone) {
                previousMaghrib = prev
            }
        }
        
        return PrayerDay(
            date: calendar.startOfDay(for: date),
            imsak: imsak,
            maghrib: maghrib,
            nextImsak: nextImsak,
            nextMaghrib: nextMaghrib,
            previousMaghrib: previousMaghrib
        )
    }
    
    /// "HH:mm" formatındaki vakti, verilen gün ve timezone'a göre Date'e çevirir.
    private static func parseTime(_ timeString: String, for date: Date, timeZoneIdentifier: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let parsed = formatter.date(from: timeString) else { return nil }
        let calendar = Calendar.current
        var comps = calendar.dateComponents(in: formatter.timeZone ?? .current, from: date)
        let timeComps = calendar.dateComponents([.hour, .minute], from: parsed)
        comps.hour = timeComps.hour
        comps.minute = timeComps.minute
        comps.second = 0
        return calendar.date(from: comps)
    }
}
