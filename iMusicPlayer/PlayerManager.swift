//
//  PlayerManager.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import Foundation
import AVFoundation
import MediaPlayer

class PlayerManager: ObservableObject {
    static let shared = PlayerManager()
    
    @Published var isPlaying: Bool = false
    @Published var currentSongTitle: String = "未播放"
    @Published var currentSong: Song?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var volume: Float = 0.5 {
        didSet {
            player?.volume = volume
        }
    }
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    private init() {
        setupAudioSession()
        setupRemoteTransportControls()
        setupNowPlayingInfoCenter()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            self.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func setupNowPlayingInfoCenter() {
        MPNowPlayingInfoCenter.default().nowPlayingInfo = [
            MPMediaItemPropertyTitle: currentSongTitle
        ]
    }
    
    func playSong(_ song: Song) {
        do {
            player = try AVAudioPlayer(contentsOf: song.url)
            player?.volume = volume
            player?.play()
            isPlaying = true
            currentSongTitle = song.title
            currentSong = song
            duration = player?.duration ?? 0
            startTimer()
            updateNowPlayingInfo()
        } catch {
            print("播放歌曲出错：\(error)")
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        startTimer()
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        timer?.invalidate()
        updateNowPlayingInfo()
    }
    
    func playNext() {
        // 实现播放下一首歌曲的逻辑
    }
    
    func playPrevious() {
        // 实现播放上一首歌曲的逻辑
    }
    
    func seek(to time: TimeInterval) {
        player?.currentTime = time
        currentTime = time
        updateNowPlayingInfo()
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTime = self.player?.currentTime ?? 0
            self.updateNowPlayingInfo()
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let song = currentSong else { return }
        
        var nowPlayingInfo: [String: Any] = [
            MPMediaItemPropertyTitle: song.title,
            MPMediaItemPropertyArtist: song.artist,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? 1.0 : 0.0
        ]
        
        if let artwork = song.artwork {
            nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: artwork.size) { _ in
                artwork
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    deinit {
        timer?.invalidate()
    }
}
