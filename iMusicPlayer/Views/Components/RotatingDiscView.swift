import SwiftUI

struct RotatingDiscView: View {
    let isPlaying: Bool
    @Environment(\.themeColors) var theme
    
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var innerRotation: Double = 0
    
    var body: some View {
        ZStack {
            // 外圈发光效果
            Circle()
                .fill(theme.accent)
                .blur(radius: 20)
                .opacity(isPlaying ? 0.3 : 0.1)
                .scaleEffect(isPlaying ? 1.2 : 1.0)
                .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPlaying)
            
            // 外圈黑胶唱片
            Circle()
                .fill(Color.black)
                .overlay(
                    Circle()
                        .stroke(theme.accent.opacity(0.5), lineWidth: 2)
                )
            
            // 唱片纹理 - 外圈
            ForEach(0..<36, id: \.self) { index in
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 1, height: 20)
                    .offset(y: -130)
                    .rotationEffect(.degrees(Double(index) * 10))
            }
            .rotationEffect(.degrees(rotation))
            
            // 中间圆环
            Circle()
                .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                .frame(width: 200, height: 200)
            
            // 内圈花纹
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [theme.accent.opacity(0.3), .black]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 110
                    )
                )
                .frame(width: 160, height: 160)
                .overlay(
                    // 内圈纹理
                    ForEach(0..<24, id: \.self) { index in
                        Rectangle()
                            .fill(theme.accent.opacity(0.2))
                            .frame(width: 1, height: 60)
                            .offset(y: -30)
                            .rotationEffect(.degrees(Double(index) * 15))
                    }
                )
                .rotationEffect(.degrees(innerRotation))
            
            // 中心圆点
            Circle()
                .fill(theme.accent.opacity(0.5))
                .frame(width: 20, height: 20)
                .shadow(color: theme.accent.opacity(0.5), radius: 5)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.5), lineWidth: 1)
                )
        }
        .frame(width: 280, height: 280)
        .rotationEffect(.degrees(rotation))
        .scaleEffect(scale)
        .onAppear {
            if isPlaying {
                startPlayingAnimation()
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                startPlayingAnimation()
            } else {
                stopPlayingAnimation()
            }
        }
    }
    
    private func startPlayingAnimation() {
        withAnimation(Animation.linear(duration: 4).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        withAnimation(Animation.linear(duration: 3).repeatForever(autoreverses: false)) {
            innerRotation = -360
        }
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)) {
            scale = 1.0
        }
    }
    
    private func stopPlayingAnimation() {
        withAnimation(.easeOut) {
            rotation = rotation.truncatingRemainder(dividingBy: 360)
            innerRotation = innerRotation.truncatingRemainder(dividingBy: 360)
            scale = 0.95
        }
    }
}

#Preview {
    ZStack {
        Color.black
        RotatingDiscView(isPlaying: true)
    }
} 