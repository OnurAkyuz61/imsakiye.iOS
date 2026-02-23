//
//  SettingsView.swift
//  İftar & Sahur Timer
//
//  Sekme 2: Anlık konum veya şehir arama ile konum seçimi.
//

import SwiftUI
import CoreLocation
import MapKit

struct SettingsView: View {
    @ObservedObject var viewModel: TimerViewModel
    @ObservedObject var locationManager: LocationManager
    @ObservedObject private var notificationManager = NotificationManager.shared

    @State private var searchText: String = ""
    @State private var searchResults: [CLPlacemark] = []
    @State private var isSearching: Bool = false
    @FocusState private var isSearchFocused: Bool
    
    private let geocoder = CLGeocoder() // Used when iOS < 26
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        viewModel.useCurrentLocation()
                    } label: {
                        Label("Anlık Konumu Kullan", systemImage: "location.fill")
                            .font(.body.weight(.medium))
                    }
                    .disabled(viewModel.useDeviceLocation && locationManager.hasValidLocation)
                } header: {
                    Text("Konum")
                } footer: {
                    Text("Cihazınızın GPS konumuna göre namaz vakitleri hesaplanır.")
                }
                
                Section {
                    HStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Şehir ara (örn. İstanbul, Ankara)", text: $searchText)
                            .textFieldStyle(.plain)
                            .focused($isSearchFocused)
                            .onSubmit {
                                performSearch()
                            }
                        if !searchText.isEmpty {
                            Button {
                                searchText = ""
                                searchResults = []
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    
                    if isSearching {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding()
                    } else if !searchResults.isEmpty {
                        ForEach(Array(searchResults.enumerated()), id: \.offset) { _, place in
                            cityRow(place: place)
                        }
                    }
                } header: {
                    Text("Şehir ile seç")
                } footer: {
                    Text("Şehir adı yazıp arayın; listeden seçtiğinizde vakitler o konuma göre güncellenir.")
                }
                
                if viewModel.manualPlace != nil {
                    Section {
                        if let place = viewModel.manualPlace {
                            Label(place.name, systemImage: "mappin.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text("Seçili konum")
                    }
                }

                Section {
                    ForEach(IftarReminder.allCases) { reminder in
                        Toggle(isOn: binding(for: reminder)) {
                            Label(reminder.rawValue, systemImage: iconForReminder(reminder))
                        }
                    }
                } header: {
                    Text("Bildirimler")
                } footer: {
                    Text("İftar vaktine kala ve iftar anında bildirim alırsınız. Bildirimler için izin vermeniz gerekebilir.")
                }
            }
            .navigationTitle("Ayarlar")
            .scrollContentBackground(.visible)
        }
    }
    
    private func cityRow(place: CLPlacemark) -> some View {
        let name = place.locality ?? place.administrativeArea ?? place.country ?? "—"
        let subtitle = [place.administrativeArea, place.country]
            .compactMap { $0 }
            .filter { $0 != name }
            .joined(separator: ", ")
        
        return Button {
            selectPlace(place: place, name: name)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(.primary)
                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    private func performSearch() {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        
        isSearching = true
        searchResults = []
        
        if #available(iOS 26.0, *) {
            Task {
                guard let request = MKGeocodingRequest(addressString: query) else {
                    await MainActor.run { isSearching = false }
                    return
                }
                do {
                    let mapItems = try await request.mapItems
                    await MainActor.run {
                        searchResults = mapItems.map(\.placemark)
                        isSearching = false
                    }
                } catch {
                    await MainActor.run {
                        searchResults = []
                        isSearching = false
                    }
                }
            }
        } else {
            geocoder.geocodeAddressString(query) { placemarks, _ in
                DispatchQueue.main.async {
                    isSearching = false
                    searchResults = placemarks ?? []
                }
            }
        }
    }
    
    private func selectPlace(place: CLPlacemark, name: String) {
        guard let location = place.location else { return }
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        viewModel.setManualPlace(name: name, lat: lat, lon: lon)
        searchText = ""
        searchResults = []
        isSearchFocused = false
    }

    private func binding(for reminder: IftarReminder) -> Binding<Bool> {
        Binding(
            get: { notificationManager.isEnabled(reminder) },
            set: { newValue in
                notificationManager.setEnabled(reminder, newValue)
                viewModel.rescheduleIftarNotifications()
            }
        )
    }

    private func iconForReminder(_ reminder: IftarReminder) -> String {
        switch reminder {
        case .oneHour: return "clock.badge"
        case .thirtyMin: return "clock"
        case .tenMin: return "bell"
        case .fiveMin: return "bell.badge"
        case .atIftar: return "moon.stars.fill"
        }
    }
}

#Preview {
    SettingsView(
        viewModel: TimerViewModel(locationManager: LocationManager()),
        locationManager: LocationManager()
    )
}
