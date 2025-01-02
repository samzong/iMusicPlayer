import SwiftUI

struct SongRow: View {
    let song: Song
    let isPlaying: Bool
    let onPlay: () -> Void
    
    var body: some View {
        HStack {
            // 歌曲信息
            Text(song.title)
                .font(.headline)
                .foregroundColor(isPlaying ? .blue : .primary)
            
            Spacer()
            
            // 播放状态指示器
            if isPlaying {
                Image(systemName: "speaker.wave.2.fill")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())  // 使整行可点击
        .onTapGesture {
            onPlay()
        }
    }
} 