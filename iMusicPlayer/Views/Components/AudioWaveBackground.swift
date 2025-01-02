import SwiftUI

struct AudioWaveBackground: View {
    let isPlaying: Bool
    @Environment(\.themeColors) var theme
    
    // 波形参数
    private let numberOfBars = 20
    @State private var barHeights: [CGFloat] = []
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 4) {
                ForEach(0..<numberOfBars, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(theme.accent.opacity(0.3))
                        .frame(width: 4, height: barHeights[safe: index] ?? 20)
                        .animation(
                            Animation
                                .easeInOut(duration: 0.5)
                                .repeatForever()
                                .delay(Double(index) * 0.1),
                            value: isPlaying
                        )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear {
                setupBars(in: geometry)
            }
            .onChange(of: isPlaying) { playing in
                if playing {
                    animateBars(in: geometry)
                } else {
                    resetBars(in: geometry)
                }
            }
        }
    }
    
    private func setupBars(in geometry: GeometryProxy) {
        let maxHeight = geometry.size.height * 0.7
        barHeights = Array(repeating: maxHeight * 0.3, count: numberOfBars)
        if isPlaying {
            animateBars(in: geometry)
        }
    }
    
    private func animateBars(in geometry: GeometryProxy) {
        let maxHeight = geometry.size.height * 0.7
        let minHeight = maxHeight * 0.2
        
        for index in 0..<numberOfBars {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.1) {
                withAnimation(
                    Animation
                        .easeInOut(duration: 0.5)
                        .repeatForever()
                        .delay(Double(index) * 0.1)
                ) {
                    barHeights[index] = CGFloat.random(in: minHeight...maxHeight)
                }
            }
        }
    }
    
    private func resetBars(in geometry: GeometryProxy) {
        let maxHeight = geometry.size.height * 0.7
        withAnimation(.easeOut(duration: 0.3)) {
            barHeights = Array(repeating: maxHeight * 0.3, count: numberOfBars)
        }
    }
}

// 安全数组访问扩展
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ZStack {
        Color.black
        AudioWaveBackground(isPlaying: true)
    }
} 