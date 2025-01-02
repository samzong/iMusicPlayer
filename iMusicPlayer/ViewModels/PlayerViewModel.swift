import Foundation
import Combine
import AVFoundation

class PlayerViewModel: ObservableObject {
    @Published var currentSong: Song?
    @Published var isPlaying: Bool = false
    
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
    }
    
    // MARK: - Public Methods
    func togglePlayPause() {
        if isPlaying {
            playerService.pause()
        } else {
            playerService.play()
        }
    }
    
    func playNext() {
        playerService.playNext()
    }
    
    func playPrevious() {
        playerService.playPrevious()
    }
} 