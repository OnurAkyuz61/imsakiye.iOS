//
//  HomeView.swift
//  İftar & Sahur Timer
//
//  Sekme 1: Sayaç ekranı, toast uyarı, modern İmsak/Akşam kutuları.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: TimerViewModel
    
    var body: some View {
        ZStack {
            SkyBackgroundView(
                isDaytime: viewModel.isDaytime,
                progress: viewModel.celestialProgress
            )
            
            SunMoonArcView(
                progress: viewModel.celestialProgress,
                isDaytime: viewModel.isDaytime
            )
            
            VStack(spacing: 0) {
                locationBar
                    .padding(.top, 56)
                
                Spacer(minLength: 0)
                
                GlassmorphicCardView(
                    title: viewModel.isIftarCountdown ? "İftara Kalan Süre" : "Sahura Kalan Süre",
                    countdownText: viewModel.countdownText,
                    isLoading: viewModel.isLoading
                )
                .padding(.horizontal, 32)
                
                Spacer(minLength: 0)
                
                prayerTimesBar
                    .padding(.bottom, 48)
            }
            
            // Zarif toast uyarı (blur + ikon)
            if let error = viewModel.errorMessage {
                errorToast(message: error)
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
        HStack(spacing: 20) {
            timeChip(
                title: "İmsak",
                time: viewModel.imsakTimeText,
                icon: "sunrise.fill"
            )
            timeChip(
                title: "Akşam",
                time: viewModel.maghribTimeText,
                icon: "sunset.fill"
            )
        }
        .padding(.horizontal, 24)
    }
    
    private func timeChip(title: String, time: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.9))
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                Text(time)
                    .font(.title2.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white.opacity(0.2))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.35), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }
    
    private func errorToast(message: String) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundStyle(.yellow)
                Text(message)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 24)
            .padding(.bottom, 100)
        }
    }
}

#Preview {
    HomeView(viewModel: TimerViewModel(locationManager: LocationManager()))
}
