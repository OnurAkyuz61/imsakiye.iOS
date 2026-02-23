//
//  PrayerTimes.swift
//  İftar & Sahur Timer
//
//  Aladhan API yanıt modelleri ve uygulama alan modeli.
//

import Foundation

// MARK: - API Response (Aladhan)

struct AladhanAPIResponse: Decodable {
    let code: Int
    let status: String
    let data: AladhanData
}

struct AladhanData: Decodable {
    let timings: AladhanTimings
    let date: AladhanDate
    let meta: AladhanMeta?
}

struct AladhanTimings: Decodable {
    /// Sahur bitişi (yeme içme sonu) — İmsak
    let Imsak: String
    /// Fecir / Şafak
    let Fajr: String
    let Sunrise: String
    let Dhuhr: String
    let Asr: String
    let Sunset: String
    /// İftar vakti — Akşam
    let Maghrib: String
    let Isha: String
    let Midnight: String?
    
    enum CodingKeys: String, CodingKey {
        case Imsak, Fajr, Sunrise, Dhuhr, Asr, Sunset, Maghrib, Isha, Midnight
    }
}

struct AladhanDate: Decodable {
    let readable: String
    let timestamp: String?
    let hijri: AladhanHijri?
    let gregorian: AladhanGregorian?
}

struct AladhanHijri: Decodable {
    let date: String
    let month: AladhanMonth?
}

struct AladhanMonth: Decodable {
    let en: String?
    let ar: String?
}

struct AladhanGregorian: Decodable {
    let date: String
}

struct AladhanMeta: Decodable {
    let latitude: Double
    let longitude: Double
    let timezone: String?
}

// MARK: - Domain Model

/// Uygulama içinde kullanılan namaz vakti modeli.
/// İmsak (Sahur sonu) ve Maghrib (İftar) tarih nesneleri ile çalışır.
struct PrayerDay {
    /// Bugünün tarihi (gece yarısı referans)
    let date: Date
    /// İmsak vakti (Sahur sonu — yeme içme bitişi)
    let imsak: Date
    /// Akşam / İftar vakti
    let maghrib: Date
    /// Ertesi günün İmsak vakti (Sahur sayacı için)
    let nextImsak: Date?
    /// Önceki günün Akşam vakti (gece yarısından imsaka progress için)
    let previousMaghrib: Date?
    
    /// İmsak–Maghrib arası toplam süre (saniye) — gündüz süresi
    var dayDuration: TimeInterval {
        maghrib.timeIntervalSince(imsak)
    }
    
    /// Gündüzde şu anki ilerleme oranı (0...1). 0 = İmsak, 1 = Maghrib.
    /// Sadece imsak <= now <= maghrib aralığında anlamlı.
    func dayProgress(now: Date = Date()) -> Double {
        guard now >= imsak && now <= maghrib, dayDuration > 0 else {
            if now < imsak { return 0 }
            return 1
        }
        return (now.timeIntervalSince(imsak)) / dayDuration
    }
    
    /// Gece ilerleme oranı (0...1). Maghrib = 0, nextImsak = 1.
    /// Sadece maghrib <= now <= nextImsak aralığında anlamlı.
    func nightProgress(now: Date = Date()) -> Double {
        guard let next = nextImsak, now >= maghrib && now <= next else {
            if now < maghrib { return 0 }
            return 1
        }
        let nightDuration = next.timeIntervalSince(maghrib)
        guard nightDuration > 0 else { return 0 }
        return (now.timeIntervalSince(maghrib)) / nightDuration
    }
    
    /// Gece yarısından bugünkü İmsak'a: önceki_aksam → imsak ilerleme (0...1).
    /// Sadece now < imsak ve previousMaghrib varsa anlamlı.
    func nightProgressBeforeImsak(now: Date = Date()) -> Double {
        guard let prev = previousMaghrib else {
            return now < imsak ? 0 : 1
        }
        if now >= prev && now < imsak {
            let span = imsak.timeIntervalSince(prev)
            guard span > 0 else { return 0 }
            return (now.timeIntervalSince(prev)) / span
        }
        if now < imsak { return 0 }
        return 1
    }
}
