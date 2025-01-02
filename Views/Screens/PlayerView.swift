import SwiftUI

struct PlayerView: View {
    @ObservedObject var viewModel: PlayerViewModel
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // 歌曲信息 (1/4 位置)
                VStack {
                    if let currentSong = viewModel.currentSong {
                        Text(currentSong.title)
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .multilineTextAlignment(.center)
                    } else {
                        Text("未播放")
                            .font(.title)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(height: geometry.size.height / 4)
                .frame(maxWidth: .infinity)
                
                // 播放控制 (居中位置)
                Spacer()
                    .frame(height: geometry.size.height / 8) // 调整到中心位置
                
                HStack(spacing: 60) {
                    Button(action: viewModel.playPrevious) {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 44))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Button(action: viewModel.togglePlayPause) {
                        Image(systemName: viewModel.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 88))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    
                    Button(action: viewModel.playNext) {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 44))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
        .background(colorScheme == .dark ? Color.black : Color.white)
        .edgesIgnoringSafeArea(.all)
    }
} 