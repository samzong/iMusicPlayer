import SwiftUI

struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // 当前播放歌曲信息
            if let currentSong = viewModel.currentSong {
                Text(currentSong.title)
                    .font(.title)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            } else {
                Text("未播放")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // 播放控制
            HStack(spacing: 40) {
                // 上一首
                Button(action: viewModel.playPrevious) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
                
                // 播放/暂停
                Button(action: viewModel.togglePlayPause) {
                    Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.primary)
                }
                
                // 下一首
                Button(action: viewModel.playNext) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                        .foregroundColor(.primary)
                }
            }
            .padding(.bottom, 50)
        }
        .padding()
    }
} 