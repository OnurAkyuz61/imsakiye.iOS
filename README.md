<div align="center">
  <img src="imsakiye/Assets.xcassets/AppLogo.imageset/AppLogo-1024.png" width="120" alt="İmsakiye" />
</div>

<div align="center">

# İmsakiye

Ramazan'da iftar ve sahur vakitlerini takip etmek için iOS uygulaması.

Konumunuza göre namaz vakitleri hesaplanır; iftara veya sahura kalan süreyi anlık geri sayım ile gösterir.

</div>

---

## Özellikler

- **İftara / sahura kalan süre** — Anlık saate göre doğru hedef vakit (İmsak öncesi → Sahur, İmsak–Akşam → İftar, Akşam sonrası → Sahur)
- **Konum bazlı vakitler** — [Aladhan API](https://aladhan.com/) ile enlem/boylam'a göre hesaplanan İmsak ve Akşam vakitleri
- **Anlık konum veya şehir seçimi** — Cihaz konumu veya Ayarlar'dan manuel şehir
- **Gündüz/gece arayüzü** — Güneş/Ay yayı ve gökyüzü arka planı ile vakit ilerlemesi
- SwiftUI ile modern arayüz (MVVM)

## Gereksinimler

- iOS 26.0+
- Xcode 26.0+
- Swift 5.9+

## Kurulum

1. Depoyu klonlayın:

   ```bash
   git clone https://github.com/onurakyuz/imsakiye.iOS.git
   cd imsakiye.iOS
   ```

2. Xcode ile **imsakiye.xcodeproj** dosyasını açın.

3. Simülatör veya bağlı cihaz seçip **Run** (⌘R) ile projeyi çalıştırın.

## Proje yapısı

```
imsakiye.iOS/
├── imsakiye.xcodeproj
└── imsakiye/
    ├── imsakiyeApp.swift              # Uygulama giriş noktası
    ├── ContentView.swift
    ├── Item.swift
    ├── ViewModels/
    │   └── TimerViewModel.swift       # Geri sayım ve vakit mantığı
    ├── Views/
    │   ├── MainTabView.swift          # Ana tab bar
    │   ├── HomeView.swift             # İftar/Sahur sayacı
    │   ├── RamadanCalendarView.swift  # Ramazan takvimi
    │   ├── SettingsView.swift         # Ayarlar
    │   ├── AboutView.swift            # Hakkında
    │   ├── MainTimerView.swift
    │   ├── GlassmorphicCardView.swift
    │   ├── SunMoonArcView.swift       # Güneş/Ay yayı
    │   └── SkyBackgroundView.swift    # Gökyüzü arka planı
    ├── Models/
    │   └── PrayerTimes.swift          # PrayerDay, Aladhan API modelleri
    ├── Managers/
    │   ├── NetworkManager.swift       # Aladhan API istekleri
    │   ├── LocationManager.swift      # Konum
    │   └── NotificationManager.swift
    ├── Utilities/
    │   └── Date+Prayer.swift
    └── Assets.xcassets                # App ikonu, logo, renkler
```

## Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır.

## Katkıda bulunma

1. Bu depoyu fork edin.
2. Yeni bir dal oluşturun: `git checkout -b feature/yeni-ozellik`
3. Değişikliklerinizi commit edin: `git commit -m 'Yeni özellik eklendi'`
4. Dalı push edin: `git push origin feature/yeni-ozellik`
5. Pull Request açın.

---

<div align="center">

**Geliştirici:** [Onur Akyüz](https://onurakyuz.com)

</div>
