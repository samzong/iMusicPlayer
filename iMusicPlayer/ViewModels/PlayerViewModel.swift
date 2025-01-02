import Foundation
import Combine
import AVFoundation

class PlayerViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    
    private let playerService: PlayerService
    private var cancellables = Set<AnyCancellable>()
    
    init(playerService: PlayerService = .shared) {
        self.playerService = playerService
        setupBindings()
    }
    
    private func setupBindings() {
        playerService.$currentSong
            .assign(to: &$currentSong)
        
        playerService.$isPlaying
            .assign(to: &$isPlaying)
        
        playerService.$currentTime
            .assign(to: &$currentTime)
        
        playerService.$duration
            .assign(to: &$duration)
    }
    
    // MARK: - Public Methods
    func togglePlayPause() {
        playerService.togglePlayPause()
    }
    
    func playNext() {
        playerService.playNext()
    }
    
    func playPrevious() {
        playerService.playPrevious()
    }
    
    // 格式化时间
    func formatTime(_ timeInterval: TimeInterval) -> String {
        // 处理特殊情况
        guard !timeInterval.isNaN && !timeInterval.isInfinite && timeInterval >= 0 else {
            return "0:00"
        }
        
        let totalSeconds = Int(floor(timeInterval))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
} 