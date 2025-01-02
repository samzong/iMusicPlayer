import Foundation
import AVFoundation
import MediaPlayer
import Combine

class PlayerService: ObservableObject {
    static let shared = PlayerService()
    
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private var player: AVPlayer?
    private var songService: SongService
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(songService: SongService = .shared) {
        self.songService = songService
        setupAudioSession()
        setupRemoteTransportControls()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            
            // 请求系统权限显示播放控制
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [.allowBluetooth, .allowBluetoothA2DP])
            
            // 配置后台播放
            let commandCenter = MPRemoteCommandCenter.shared()
            UIApplication.shared.beginReceivingRemoteControlEvents()
        } catch {
            print("设置音频会话失败: \(error)")
        }
    }
    
    private func setupRemoteTransportControls() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 播放命令
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        // 暂停命令
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        // 下一首命令
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        // 上一首命令
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        // 跳转命令
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.player,
                  let positionEvent = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            player.seek(to: CMTime(seconds: positionEvent.positionTime, preferredTimescale: 1000))
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let currentSong = currentSong else { return }
        
        var nowPlayingInfo = [String: Any]()
        
        // 设置歌曲信息
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSong.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "iMusicPlayer"
        
        // 设置时长
        if let duration = player?.currentItem?.duration.seconds, !duration.isNaN {
            nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
        }
        
        // 设置当前播放位置
        if let currentTime = player?.currentTime().seconds, !currentTime.isNaN {
            nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        
        // 设置播放速率
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        // 更新系统播放器信息
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Public Methods
    func playSong(_ song: Song) {
        // 如果是同一首歌，继续播放
        if currentSong?.id == song.id {
            play()
            return
        }
        
        // 停止当前播放
        stop()
        
        // 创建新的播放器
        let playerItem = AVPlayerItem(url: song.url)
        player = AVPlayer(playerItem: playerItem)
        
        // 设置时间观察器
        if let player = player {
            timeObserver = player.addPeriodicTimeObserver(forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main) { [weak self] time in
                guard let self = self else { return }
                self.currentTime = time.seconds
                self.duration = player.currentItem?.duration.seconds ?? 0
                self.updateNowPlayingInfo()
            }
        }
        
        // 更新状态
        currentSong = song
        
        // 开始播放
        play()
        
        // 监听播放完成
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(playerDidFinishPlaying),
            name: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem
        )
    }
    
    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        updateNowPlayingInfo()
    }
    
    func playNext() {
        guard let currentSong = currentSong,
              let nextSong = songService.getNextSong(after: currentSong) else {
            return
        }
        playSong(nextSong)
    }
    
    func playPrevious() {
        guard let currentSong = currentSong,
              let previousSong = songService.getPreviousSong(before: currentSong) else {
            return
        }
        playSong(previousSong)
    }
    
    @objc private func playerDidFinishPlaying() {
        playNext()
    }
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
        NotificationCenter.default.removeObserver(self)
    }
} 