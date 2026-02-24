//
//  AboutView.swift
//  İftar & Sahur Timer
//
//  Sekme 3: Uygulama logosu, versiyon, hakkında metni ve geliştirici linki.
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
            VStack(spacing: 0) {
                // Logo ve başlık alanı
                VStack(spacing: 20) {
                    Image("AppLogo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(.secondary.opacity(0.15), lineWidth: 0.5)
                        )
                        .padding(.top, 32)
                    
                    Text("İmsakiye")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                    
                    Text("Versiyon \(appVersion) (\(buildNumber))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 28)
                
                // Hakkında kartı
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Text("Hakkında")
                            .font(.headline.weight(.semibold))
                    }
                    
                    Text("Bu uygulama, Ramazan ayında iftar ve sahur vakitlerini konumunuza göre gösterir. Aladhan API kullanılarak namaz vakitleri hesaplanır. İsterseniz anlık konumunuzu kullanabilir veya Ayarlar üzerinden şehir seçebilirsiniz.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineSpacing(4)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(.secondary.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(.secondary.opacity(0.08), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
                
                // Geliştirici & web sitesi linki
                VStack(spacing: 12) {
                    Text("Geliştirici")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                    
                    Link(destination: URL(string: "https://onurakyuz.com")!) {
                        HStack(spacing: 10) {
                            Image(systemName: "person.crop.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Onur Akyüz")
                                    .font(.body.weight(.semibold))
                                    .foregroundStyle(.primary)
                                Text("onurakyuz.com")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(.secondary.opacity(0.08))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .stroke(.secondary.opacity(0.1), lineWidth: 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 48)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Hakkında")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        AboutView()
    }
}
