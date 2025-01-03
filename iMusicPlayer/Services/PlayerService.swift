import Foundation
import AVFoundation
import MediaPlayer

class PlayerService: ObservableObject {
    static let shared = PlayerService()
    
    @Published private(set) var currentSong: Song?
    @Published private(set) var isPlaying: Bool = false
    @Published private(set) var currentTime: TimeInterval = 0
    @Published private(set) var duration: TimeInterval = 0
    
    private var player: AVPlayer? {
        willSet {
            if let oldPlayer = player {
                oldPlayer.pause()
                if let timeObserver = timeObserver {
                    oldPlayer.removeTimeObserver(timeObserver)
                }
            }
        }
    }
    
    private weak var songService: SongService?
    private var timeObserver: Any?
    private var itemObserver: NSKeyValueObservation?
    private var lastInfoUpdateTime: TimeInterval = 0
    private static let minimumUpdateInterval: TimeInterval = 5.0
    private var notificationObservers: [Any] = []
    
    private init(songService: SongService = .shared) {
        self.songService = songService
        setupAudioSession()
        #if os(iOS)
        setupRemoteControls()
        #endif
        setupNotifications()
    }
    
    private func setupAudioSession() {
        #if os(iOS)
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setActive(false)
            try session.setCategory(.playback, mode: .default, options: [.allowAirPlay, .allowBluetooth, .allowBluetoothA2DP])
            try session.setActive(true)
            UIApplication.shared.beginReceivingRemoteControlEvents()
            setupNowPlaying()
        } catch {
            print("设置音频会话失败: \(error)")
        }
        #else
        // macOS 不需要特殊的音频会话设置
        setupNowPlaying()
        #endif
    }
    
    private func setupRemoteControls() {
        #if os(iOS)
        let commandCenter = MPRemoteCommandCenter.shared()
        
        // 启用所有控制命令
        [commandCenter.playCommand,
         commandCenter.pauseCommand,
         commandCenter.nextTrackCommand,
         commandCenter.previousTrackCommand,
         commandCenter.togglePlayPauseCommand,
         commandCenter.changePlaybackPositionCommand].forEach { $0.isEnabled = true }
        
        // 播放/暂停
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.togglePlayPauseCommand.addTarget { [weak self] _ in
            self?.togglePlayPause()
            return .success
        }
        
        // 上一首/下一首
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.playNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.playPrevious()
            return .success
        }
        
        // 进度控制
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self,
                  let player = self.player,
                  let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            player.seek(to: CMTime(seconds: event.positionTime, preferredTimescale: 1))
            self.updateNowPlayingInfo(force: true)
            return .success
        }
        #endif
    }
    
    private func setupNotifications() {
        #if os(iOS)
        // 处理音频中断
        let observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            self?.handleInterruption(notification)
        }
        notificationObservers.append(observer)
        #endif
        
        // 处理播放完成通知（所有平台通用）
        let playbackObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.playNext()
        }
        notificationObservers.append(playbackObserver)
    }
    
    #if os(iOS)
    private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            pause()
        case .ended:
            guard let optionsValue = userInfo[AVAudioSessionInterruptionOptionKey] as? UInt else { return }
            let options = AVAudioSession.InterruptionOptions(rawValue: optionsValue)
            if options.contains(.shouldResume) {
                play()
            }
        @unknown default:
            break
        }
    }
    #endif
    
    private func setupNowPlaying() {
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPNowPlayingInfoPropertyIsLiveStream] = false
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = 0.0
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    private func updateNowPlayingInfo(force: Bool = false) {
        let currentTime = Date().timeIntervalSince1970
        guard force || (currentTime - lastInfoUpdateTime) >= Self.minimumUpdateInterval else { return }
        lastInfoUpdateTime = currentTime
        
        guard let currentSong = currentSong else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nil
            return
        }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = currentSong.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = "iMusicPlayer"
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        if let player = player {
            let time = CMTimeGetSeconds(player.currentTime())
            let duration = CMTimeGetSeconds(player.currentItem?.duration ?? .zero)
            
            if !time.isNaN {
                nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = time
                self.currentTime = time
            }
            if !duration.isNaN {
                nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = duration
                self.duration = duration
            }
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
    }
    
    // MARK: - Public Methods
    func playSong(_ song: Song) {
        if currentSong?.id == song.id {
            play()
            return
        }
        
        stop()
        setupPlayer(with: song.url)
        currentSong = song
        play()
    }
    
    private func setupPlayer(with url: URL) {
        let asset = AVURLAsset(url: url)
        let playerItem = AVPlayerItem(asset: asset, automaticallyLoadedAssetKeys: ["playable", "duration"])
        playerItem.preferredForwardBufferDuration = 10
        
        player = AVPlayer(playerItem: playerItem)
        player?.automaticallyWaitsToMinimizeStalling = true
        
        let interval = CMTime(seconds: 5.0, preferredTimescale: 1)
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] _ in
            self?.updateNowPlayingInfo()
        }
        
        itemObserver = playerItem.observe(\.status) { [weak self] item, _ in
            if item.status == .readyToPlay {
                self?.updateNowPlayingInfo(force: true)
            }
        }
    }
    
    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo(force: true)
        
        #if os(iOS)
        do {
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("激活音频会话失败: \(error)")
        }
        #endif
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo(force: true)
    }
    
    func stop() {
        player?.pause()
        
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
        
        itemObserver?.invalidate()
        itemObserver = nil
        
        player = nil
        isPlaying = false
        currentTime = 0
        duration = 0
        updateNowPlayingInfo(force: true)
    }
    
    func playNext() {
        guard let currentSong = currentSong,
              let nextSong = songService?.getNextSong(after: currentSong) else {
            return
        }
        playSong(nextSong)
    }
    
    func playPrevious() {
        guard let currentSong = currentSong,
              let previousSong = songService?.getPreviousSong(before: currentSong) else {
            return
        }
        playSong(previousSong)
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if currentSong != nil {
            play()
        } else if let firstSong = songService?.songs.first {
            playSong(firstSong)
        }
    }
    
    deinit {
        cleanup()
    }
    
    private func cleanup() {
        stop()
        notificationObservers.forEach {
            NotificationCenter.default.removeObserver($0)
        }
        notificationObservers.removeAll()
        
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
    }
}