import Foundation
import AVFoundation
import MediaPlayer
import Combine

class PlayerService: ObservableObject {
    static let shared = PlayerService()
    
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    
    private var player: AVPlayer?
    private var songService: SongService
    private var timeObserver: Any?
    private var cancellables = Set<AnyCancellable>()
    
    init(songService: SongService = .shared) {
        self.songService = songService
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("设置音频会话失败: \(error)")
        }
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
        
        // 更新状态
        currentSong = song
        
        // 开始播放
        play()
    }
    
    func play() {
        player?.play()
        isPlaying = true
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
    }
    
    func stop() {
        player?.pause()
        player = nil
        isPlaying = false
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
    
    deinit {
        if let timeObserver = timeObserver {
            player?.removeTimeObserver(timeObserver)
        }
    }
} 