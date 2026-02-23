//
//  GlassmorphicCardView.swift
//  İftar & Sahur Timer
//
//  Glassmorphism sayaç kartı: geri sayım + başlık.
//

import SwiftUI

struct GlassmorphicCardView: View {
    let title: String
    let countdownText: String
    let isLoading: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text(title)
                .font(.title3.weight(.medium))
                .foregroundStyle(.white.opacity(0.95))
            
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
                    .padding(.vertical, 8)
            } else {
                Text(countdownText)
                    .font(.system(size: 52, weight: .light, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .padding(.horizontal, 24)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom).ignoresSafeArea()
        GlassmorphicCardView(
            title: "İftara Kalan Süre",
            countdownText: "02:45:33",
            isLoading: false
        )
        .padding(.horizontal, 32)
    }
}
