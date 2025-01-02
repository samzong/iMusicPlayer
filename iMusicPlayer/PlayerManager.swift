//
//  PlayerManager.swift
//  iMusicPlayer
//
//  Created by X on 11/7/24.
//

import Foundation
import AVFoundation
import MediaPlayer

enum PlayMode {
    case sequence   // 顺序播放
    case shuffle    // 随机播放
    case repeatOne  // 单曲循环
    case repeatAll  // 列表循环
    
    var iconName: String {
        switch self {
        case .sequence:   return "arrow.right"
        case .shuffle:    return "shuffle"
        case .repeatOne:  return "repeat.1"
        case .repeatAll:  return "repeat"
        }
    }
}

class PlayerManager: ObservableObject {
    static let shared = PlayerManager()
    
    @Published var isPlaying: Bool = false
    @Published var currentSongTitle: String = "未播放"
    @Published var currentSong: Song?
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var playMode: PlayMode = .sequence
    
    private var player: AVAudioPlayer?
    private var timer: Timer?
    
    private init() {
        print("PlayerManager: 初始化")
        setupAudioSession()
        setupRemoteTransportControls()
        setupNowPlayingInfoCenter()
        
        // 监听 SongManager 的歌曲列表变化，但不自动播放
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleSongsChanged),
            name: NSNotification.Name("SongsDidChange"),
            object: nil
        )
    }
    
    @objc private func handleSongsChanged() {
        print("PlayerManager: 歌曲列表已更新")
        // 移除自动播放逻辑，只打印日志
        if !SongManager.shared.songs.isEmpty {
            print("PlayerManager: 有可用歌曲，等待用户播放")
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            print("PlayerManager: 音频会话设置成功")
        } catch {
            print("PlayerManager: 设置音频会话失败: \(error)")
        }
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            print("PlayerManager: 远程控制 - 播放")
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            print("PlayerManager: 远程控制 - 暂停")
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            print("PlayerManager: 远程控制 - 下一首")
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            print("PlayerManager: 远程控制 - 上一首")
            self?.playPrevious()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            print("PlayerManager: 远程控制 - 调整进度")
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
        print("PlayerManager: 开始播放歌曲 - \(song.title)")
        do {
            // 确保文件存在
            guard FileManager.default.fileExists(atPath: song.url.path) else {
                print("PlayerManager: 歌曲文件不存在 - \(song.url.path)")
                return
            }
            
            // 停止当前播放
            player?.stop()
            player = nil
            
            // 创建新的播放器
            player = try AVAudioPlayer(contentsOf: song.url)
            player?.prepareToPlay()
            
            // 开始播放
            if player?.play() == true {
                DispatchQueue.main.async { [weak self] in
                    guard let self = self else { return }
                    self.isPlaying = true
                    self.currentSongTitle = song.title
                    self.currentSong = song
                    self.duration = self.player?.duration ?? 0
                    self.startTimer()
                    self.updateNowPlayingInfo()
                }
                print("PlayerManager: 歌曲播放成功")
            } else {
                print("PlayerManager: 歌曲播放失败")
            }
        } catch {
            print("PlayerManager: 播放歌曲出错：\(error)")
        }
    }
    
    func play() {
        print("PlayerManager: 播放请求")
        if currentSong == nil && !SongManager.shared.songs.isEmpty {
            print("PlayerManager: 从第一首开始播放")
            playSong(SongManager.shared.songs[0])
        } else if let player = player {
            print("PlayerManager: 继续播放当前歌曲")
            player.play()
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.isPlaying = true
                self.startTimer()
                self.updateNowPlayingInfo()
            }
        }
    }
    
    func pause() {
        print("PlayerManager: 暂停请求")
        player?.pause()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isPlaying = false
            self.timer?.invalidate()
            self.updateNowPlayingInfo()
        }
    }
    
    func togglePlayMode() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch self.playMode {
            case .sequence:   self.playMode = .repeatAll
            case .repeatAll:  self.playMode = .repeatOne
            case .repeatOne:  self.playMode = .shuffle
            case .shuffle:    self.playMode = .sequence
            }
            print("PlayerManager: 切换播放模式为 - \(self.playMode)")
        }
    }
    
    func playNext() {
        print("PlayerManager: 下一首请求")
        if SongManager.shared.songs.isEmpty {
            print("PlayerManager: 没有可用的歌曲")
            return
        }
        
        if currentSong == nil {
            print("PlayerManager: 没有当前歌曲，播放第一首")
            playSong(SongManager.shared.songs[0])
            return
        }
        
        guard let currentIndex = SongManager.shared.songs.firstIndex(of: currentSong!) else {
            print("PlayerManager: 当前歌曲不在列表中")
            return
        }
        
        var nextIndex: Int
        
        switch playMode {
        case .shuffle:
            nextIndex = Int.random(in: 0..<SongManager.shared.songs.count)
        case .sequence, .repeatAll:
            nextIndex = (currentIndex + 1) % SongManager.shared.songs.count
        case .repeatOne:
            nextIndex = currentIndex
        }
        
        print("PlayerManager: 播放下一首 - 索引: \(nextIndex)")
        let nextSong = SongManager.shared.songs[nextIndex]
        playSong(nextSong)
    }
    
    func playPrevious() {
        print("PlayerManager: 上一首请求")
        if SongManager.shared.songs.isEmpty {
            print("PlayerManager: 没有可用的歌曲")
            return
        }
        
        if currentSong == nil {
            print("PlayerManager: 没有当前歌曲，播放第一首")
            playSong(SongManager.shared.songs[0])
            return
        }
        
        guard let currentIndex = SongManager.shared.songs.firstIndex(of: currentSong!) else {
            print("PlayerManager: 当前歌曲不在列表中")
            return
        }
        
        var prevIndex: Int
        
        switch playMode {
        case .shuffle:
            prevIndex = Int.random(in: 0..<SongManager.shared.songs.count)
        case .sequence, .repeatAll:
            prevIndex = (currentIndex - 1 + SongManager.shared.songs.count) % SongManager.shared.songs.count
        case .repeatOne:
            prevIndex = currentIndex
        }
        
        print("PlayerManager: 播放上一首 - 索引: \(prevIndex)")
        let prevSong = SongManager.shared.songs[prevIndex]
        playSong(prevSong)
    }
    
    func seek(to time: TimeInterval) {
        print("PlayerManager: 调整进度到 \(time)")
        player?.currentTime = time
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.currentTime = time
            self.updateNowPlayingInfo()
        }
    }
    
    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.currentTime = self.player?.currentTime ?? 0
                self.updateNowPlayingInfo()
                
                // 检查是否播放完成
                if self.currentTime >= self.duration {
                    print("PlayerManager: 当前歌曲播放完成")
                    self.handlePlaybackFinished()
                }
            }
        }
    }
    
    private func handlePlaybackFinished() {
        switch playMode {
        case .repeatOne:
            print("PlayerManager: 单曲循环 - 重新播放")
            if let song = currentSong {
                playSong(song)
            }
        case .sequence:
            if let currentSong = currentSong,
               let currentIndex = SongManager.shared.songs.firstIndex(of: currentSong),
               currentIndex == SongManager.shared.songs.count - 1 {
                print("PlayerManager: 顺序播放 - 最后一首歌播放完成")
                pause()
            } else {
                print("PlayerManager: 顺序播放 - 播放下一首")
                playNext()
            }
        case .repeatAll, .shuffle:
            print("PlayerManager: 列表循环/随机播放 - 播放下一首")
            playNext()
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
        print("PlayerManager: 释放")
        timer?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
}
