import SwiftUI

struct SongRow: View {
    let song: Song
    let isPlaying: Bool
    let onPlay: () -> Void
    @Environment(\.themeColors) var theme
    
    var body: some View {
        HStack {
            // 歌曲信息
            Text(song.title)
                .font(.headline)
                .foregroundColor(isPlaying ? theme.accent : .primary)
            
            Spacer()
            
            // 播放状态指示器
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(theme.accent)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())  // 使整行可点击
        .onTapGesture {
            onPlay()
        }
        .background(theme.background.opacity(0.001))  // 添加一个几乎透明的背景以改善点击效果
        .withTheme()
    }
} 