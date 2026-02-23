//
//  AboutView.swift
//  İftar & Sahur Timer
//
//  Sekme 3: Versiyon, hakkında metni ve geliştirici linki.
//

import SwiftUI

struct AboutView: View {
    private var appVersion: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }
    
    private var buildNumber: String {
        (Bundle.main.infoDictionary?["CFBundleVersion"] as? String) ?? "1"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Logo / ikon alanı
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.secondary)
                    .padding(.top, 40)
                
                Text("İmsakiye")
                    .font(.title.weight(.bold))
                
                Text("Versiyon \(appVersion) (\(buildNumber))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hakkında")
                        .font(.headline)
                    Text("Bu uygulama, Ramazan ayında iftar ve sahur vakitlerini konumunuza göre gösterir. Aladhan API kullanılarak namaz vakitleri hesaplanır. İsterseniz anlık konumunuzu kullanabilir veya Ayarlar üzerinden şehir seçebilirsiniz.")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                Spacer(minLength: 48)
                
                // Geliştirici linki
                Link(destination: URL(string: "https://onurakyuz.com")!) {
                    HStack(spacing: 8) {
                        Text("Geliştirici:")
                            .foregroundStyle(.secondary)
                        Text("Onur Akyüz")
                            .fontWeight(.semibold)
                    }
                    .font(.body)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 24)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(.secondary.opacity(0.12))
                )
                .padding(.horizontal, 32)
                .padding(.bottom, 48)
            }
        }
        .navigationTitle("Hakkında")
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
