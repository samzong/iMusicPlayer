import SwiftUI

struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.themeColors) var theme
    
    var body: some View {
        ZStack {
            // 背景渐变
            theme.gradient
                .ignoresSafeArea()
            
            // 音频波形背景
            AudioWaveBackground(isPlaying: viewModel.isPlaying)
                .opacity(0.3)
                .blur(radius: 20)
                .ignoresSafeArea()
            
            // 主要内容
            VStack(spacing: 40) {
                Spacer()
                
                // 唱片视图
                RotatingDiscView(isPlaying: viewModel.isPlaying)
                    .shadow(color: theme.accent.opacity(0.3), radius: 20, x: 0, y: 10)
                    .overlay(
                        Circle()
                            .stroke(theme.accent.opacity(0.2), lineWidth: 1)
                            .blur(radius: 3)
                            .scaleEffect(1.02)
                    )
                
                // 当前播放歌曲信息
                VStack(spacing: 10) {
                    if let currentSong = viewModel.currentSong {
                        Text(currentSong.title)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // 播放进度
                        VStack(spacing: 8) {
                            // 进度条
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    // 背景条
                                    Rectangle()
                                        .fill(theme.accent.opacity(0.2))
                                        .frame(height: 4)
                                        .cornerRadius(2)
                                    
                                    // 进度条
                                    Rectangle()
                                        .fill(theme.accent)
                                        .frame(width: geometry.size.width * CGFloat(viewModel.currentTime / max(viewModel.duration, 1)), height: 4)
                                        .cornerRadius(2)
                                }
                            }
                            .frame(height: 4)
                            
                            // 时间标签
                            HStack {
                                Text(viewModel.formatTime(viewModel.currentTime))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer()
                                
                                Text(viewModel.formatTime(viewModel.duration))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        Text("未播放")
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: 100)  // 增加高度以容纳进度条
                
                Spacer()
                
                // 播放控制
                HStack(spacing: 50) {
                    // 上一首
                    Button(action: viewModel.playPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.title)
                            .foregroundColor(theme.accent)
                            .shadow(color: theme.accent.opacity(0.3), radius: 5)
                    }
                    
                    // 播放/暂停
                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 70))
                            .foregroundColor(theme.accent)
                            .shadow(color: theme.accent.opacity(0.3), radius: 10)
                    }
                    
                    // 下一首
                    Button(action: viewModel.playNext) {
                        Image(systemName: "forward.fill")
                            .font(.title)
                            .foregroundColor(theme.accent)
                            .shadow(color: theme.accent.opacity(0.3), radius: 5)
                    }
                }
                .padding(.bottom, 60)
            }
            .padding()
        }
        .withTheme()
    }
} 