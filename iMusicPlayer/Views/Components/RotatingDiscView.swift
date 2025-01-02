import SwiftUI

struct RotatingDiscView: View {
    let isPlaying: Bool
    
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // 外圈黑胶唱片
            Circle()
                .fill(Color.black)
                .overlay(
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 2)
                )
            
            // 内圈花纹
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [.gray.opacity(0.2), .black]),
                        center: .center,
                        startRadius: 20,
                        endRadius: 110
                    )
                )
                .frame(width: 160, height: 160)
            
            // 中心圆点
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 20, height: 20)
        }
        .frame(width: 280, height: 280)
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(Animation.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
        .onChange(of: isPlaying) { playing in
            if playing {
                withAnimation(Animation.linear(duration: 6).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                withAnimation(.easeOut) {
                    // 暂停时保持当前角度
                    rotation = rotation.truncatingRemainder(dividingBy: 360)
                }
            }
        }
    }
}

#Preview {
    RotatingDiscView(isPlaying: true)
} 