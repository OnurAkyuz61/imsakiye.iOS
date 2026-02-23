//
//  MainTabView.swift
//  İftar & Sahur Timer
//
//  Uygulamanın ana giriş noktası; alt TabBar ile 3 sekme.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var viewModel: TimerViewModel
    
    init() {
        let locationManager = LocationManager()
        _locationManager = StateObject(wrappedValue: locationManager)
        _viewModel = StateObject(wrappedValue: TimerViewModel(locationManager: locationManager))
    }
    
    var body: some View {
        TabView {
            HomeView(viewModel: viewModel)
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }
            
            SettingsView(viewModel: viewModel, locationManager: locationManager)
                .tabItem {
                    Label("Ayarlar", systemImage: "gearshape.fill")
                }
            
            AboutView()
                .tabItem {
                    Label("Hakkında", systemImage: "info.circle.fill")
                }
        }
        .tint(.primary)
    }
}

#Preview {
    MainTabView()
}
