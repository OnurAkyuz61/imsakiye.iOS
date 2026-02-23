//
//  SunMoonArcView.swift
//  İftar & Sahur Timer
//
//  Görünmez yarım daire üzerinde Güneş (gündüz) veya Ay (gece) konumu.
//

import SwiftUI

/// progress: 0 = sol uç (İmsak), 1 = sağ uç (Maghrib) veya gece için Maghrib → İmsak.
struct SunMoonArcView: View {
    let progress: Double
    let isDaytime: Bool
    
    private let arcRadius: CGFloat = 140
    private let iconSize: CGFloat = 44
    
    var body: some View {
        GeometryReader { geo in
            let centerX = geo.size.width / 2
            let centerY = geo.size.height * 0.38
            let angle = Angle.degrees(180 - progress * 180)
            let x = centerX + arcRadius * cos(CGFloat(angle.radians))
            let y = centerY - arcRadius * sin(CGFloat(angle.radians))
            
            ZStack(alignment: .center) {
                // Görünmez yay (isteğe bağlı: ince çizgi ile debug)
                Path { path in
                    path.addArc(
                        center: CGPoint(x: centerX, y: centerY),
                        radius: arcRadius,
                        startAngle: .degrees(180),
                        endAngle: .degrees(0),
                        clockwise: false
                    )
                }
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                
                Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                    .font(.system(size: iconSize))
                    .foregroundStyle(isDaytime ? .yellow : .white.opacity(0.95))
                    .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    .position(x: x, y: y)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.easeInOut(duration: 0.6), value: progress)
        .animation(.easeInOut(duration: 0.5), value: isDaytime)
    }
}

#Preview {
    ZStack {
        Color.blue.opacity(0.3).ignoresSafeArea()
        SunMoonArcView(progress: 0.5, isDaytime: true)
    }
}
