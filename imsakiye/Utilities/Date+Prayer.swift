//
//  Date+Prayer.swift
//  İftar & Sahur Timer
//
//  Namaz vakti gösterimi için tarih biçimlendirme.
//

import Foundation

extension Date {
    /// Örn: "06:17", "18:54"
    var prayerTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "tr_TR")
        return formatter.string(from: self)
    }
    
    /// Geri sayım için HH:mm:ss (saat 24'ü aşabilir)
    static func countdownString(from seconds: TimeInterval) -> String {
        let total = Int(seconds.rounded())
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }
}
