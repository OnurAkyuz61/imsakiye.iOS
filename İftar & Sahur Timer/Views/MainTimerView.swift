//
//  MainTimerView.swift
//  İftar & Sahur Timer
//
//  ZStack katmanları: Gökyüzü → Güneş/Ay yayı → Glassmorphism kart → Bilgi barları.
//

import SwiftUI

struct MainTimerView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel: TimerViewModel
    
    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _viewModel = StateObject(wrappedValue: TimerViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        ZStack {
            // Katman 1: Dinamik gökyüzü
            SkyBackgroundView(
                isDaytime: viewModel.isDaytime,
                progress: viewModel.celestialProgress
            )
            
            // Katman 2: Güneş / Ay yayı
            SunMoonArcView(
                progress: viewModel.celestialProgress,
                isDaytime: viewModel.isDaytime
            )
            
            // Katman 3 & 4: Ortada kart, üstte/altta bilgi
            VStack(spacing: 0) {
                // Üst bar: Konum
                locationBar
                    .padding(.top, 56)
                
                Spacer(minLength: 0)
                
                // Ortada glassmorphism sayaç kartı
                GlassmorphicCardView(
                    title: viewModel.isIftarCountdown ? "İftara Kalan Süre" : "Sahura Kalan Süre",
                    countdownText: viewModel.countdownText,
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal, 32)
                
                Spacer(minLength: 0)
                
                // Alt bar: İmsak & Akşam saatleri
                prayerTimesBar
                    .padding(.bottom, 48)
            }
            
            if let error = viewModel.errorMessage {
                VStack {
                    Spacer()
                    Text(error)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                        .padding()
                        .background(.black.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 24)
                        .padding(.bottom, 120)
                }
            }
        }
        .onAppear {
            viewModel.requestLocationAndFetchPrayerTimes()
        }
    }
    
    private var locationBar: some View {
        HStack {
            Spacer()
            Label(viewModel.locationDisplayName, systemImage: "location.fill")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))
            Spacer()
        }
    }
    
    private var prayerTimesBar: some View {
        HStack(spacing: 24) {
            timeChip(title: "İmsak", time: viewModel.imsakTimeText)
            timeChip(title: "Akşam", time: viewModel.maghribTimeText)
        }
        .padding(.horizontal, 24)
    }
    
    private func timeChip(title: String, time: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
            Text(time)
                .font(.title3.weight(.semibold).monospacedDigit())
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.15), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

#Preview {
    MainTimerView()
}
