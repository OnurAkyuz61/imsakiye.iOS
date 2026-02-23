//
//  SkyBackgroundView.swift
//  İftar & Sahur Timer
//
//  Saate göre değişen dinamik gökyüzü gradient'i ve gece yıldızları.
//

import SwiftUI

/// Gündüz / gün batımı / gece durumuna göre gradient ve isteğe bağlı yıldızlar.
enum SkyPhase {
    case day
    case sunset
    case night
}

struct SkyBackgroundView: View {
    let isDaytime: Bool
    let progress: Double // 0...1 (gündüz veya gece ilerlemesi)
    
    private var phase: SkyPhase {
        if isDaytime {
            if progress > 0.75 { return .sunset }
            return .day
        } else {
            return .night
        }
    }
    
    private var gradient: LinearGradient {
        switch phase {
        case .day:
            return LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.55, blue: 0.95),
                    Color(red: 0.55, green: 0.75, blue: 0.98),
                    Color(red: 0.95, green: 0.85, blue: 0.65)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .sunset:
            return LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.15, blue: 0.35),
                    Color(red: 0.85, green: 0.35, blue: 0.25),
                    Color(red: 0.95, green: 0.55, blue: 0.35),
                    Color(red: 0.98, green: 0.75, blue: 0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .night:
            return LinearGradient(
                colors: [
                    Color(red: 0.02, green: 0.02, blue: 0.12),
                    Color(red: 0.08, green: 0.05, blue: 0.22),
                    Color(red: 0.12, green: 0.08, blue: 0.28)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(gradient)
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 1.2), value: phase)
            
            if phase == .night {
                StarfieldView()
                    .opacity(0.9)
            }
        }
    }
}

/// Basit yıldız noktaları (gece gökyüzü)
private struct StarfieldView: View {
    @State private var stars: [(x: CGFloat, y: CGFloat, size: CGFloat)] = []
    
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                for star in stars {
                    let rect = CGRect(
                        x: star.x * size.width - star.size,
                        y: star.y * size.height - star.size,
                        width: star.size * 2,
                        height: star.size * 2
                    )
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(0.7 + Double(star.size) * 2))
                    )
                }
            }
            .onAppear {
                if stars.isEmpty {
                    var rng = SeededRandom(seed: 42)
                    stars = (0..<80).map { _ in
                        (x: CGFloat(rng.next()), y: CGFloat(rng.next()), size: CGFloat(0.003 + rng.next() * 0.004))
                    }
                }
            }
        }
        .ignoresSafeArea()
    }
}

private struct SeededRandom {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> Double {
        state = state &* 6364136223846793005 &+ 1442695040888963407
        return Double(state % 10000) / 10000.0
    }
}

#Preview("Day") {
    SkyBackgroundView(isDaytime: true, progress: 0.3)
}
#Preview("Night") {
    SkyBackgroundView(isDaytime: false, progress: 0.5)
}
