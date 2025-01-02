//
//  PlayerView.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import SwiftUI

struct PlayerView: View {
    @ObservedObject var playerManager = PlayerManager.shared
    @State private var sliderValue: Double = 0
    @State private var isDragging = false
    
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            
            // 专辑封面
            Image(systemName: "music.note")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
            
            // 歌曲信息
            VStack(spacing: 8) {
                Text(playerManager.currentSongTitle)
                    .font(.title2)
                    .bold()
                if let song = playerManager.currentSong {
                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            
            // 进度条
            VStack {
                Slider(
                    value: Binding(
                        get: { isDragging ? sliderValue : playerManager.currentTime },
                        set: { newValue in
                            sliderValue = newValue
                            if isDragging {
                                playerManager.seek(to: newValue)
                            }
                        }
                    ),
                    in: 0...max(playerManager.duration, 1)
                ) { dragging in
                    isDragging = dragging
                    if !dragging {
                        playerManager.seek(to: sliderValue)
                    }
                }
                
                HStack {
                    Text(formatTime(playerManager.currentTime))
                    Spacer()
                    Text("-" + formatTime(playerManager.duration - playerManager.currentTime))
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            .padding(.horizontal)
            
            // 播放控制
            HStack(spacing: 40) {
                Button(action: {
                    playerManager.playPrevious()
                }) {
                    Image(systemName: "backward.fill")
                        .font(.title)
                }
                
                Button(action: {
                    if playerManager.isPlaying {
                        playerManager.pause()
                    } else {
                        playerManager.play()
                    }
                }) {
                    Image(systemName: playerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 50))
                }
                
                Button(action: {
                    playerManager.playNext()
                }) {
                    Image(systemName: "forward.fill")
                        .font(.title)
                }
            }
            .padding()
            
            // 播放模式
            Button(action: {
                playerManager.togglePlayMode()
            }) {
                Image(systemName: playerManager.playMode.iconName)
                    .font(.title2)
                    .padding(8)
                    .background(
                        Circle()
                            .fill(Color.blue.opacity(0.1))
                            .frame(width: 40, height: 40)
                    )
            }
            .foregroundColor(.blue)
            
            Spacer()
        }
        .padding()
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
