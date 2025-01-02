import SwiftUI

struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.themeColors) var theme
    
    var body: some View {
        ZStack {
            // 背景渐变
            theme.gradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // 唱片视图
                RotatingDiscView(isPlaying: viewModel.isPlaying)
                    .shadow(color: Color.primary.opacity(0.2), radius: 10, x: 0, y: 5)
                
                // 当前播放歌曲信息
                VStack(spacing: 10) {
                    if let currentSong = viewModel.currentSong {
                        Text(currentSong.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    } else {
                        Text("未播放")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 60)
                
                Spacer()
                
                // 播放控制
                HStack(spacing: 50) {
                    // 上一首
                    Button(action: viewModel.playPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(theme.accent)
                    }
                    
                    // 播放/暂停
                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(theme.accent)
                    }
                    
                    // 下一首
                    Button(action: viewModel.playNext) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(theme.accent)
                    }
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .withTheme()
    }
} 