import Foundation
import Combine

class SongService: ObservableObject {
    static let shared = SongService()
    
    @Published var songs: [Song] = []
    
    private let userDefaults = UserDefaults.standard
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadSongs()
    }
    
    // MARK: - Song Management
    func addSong(_ song: Song) {
        // 检查是否已存在同名歌曲
        if let existingIndex = songs.firstIndex(where: { $0.title == song.title }) {
            // 如果存在，先删除旧文件
            let existingSong = songs[existingIndex]
            do {
                try FileManager.default.removeItem(at: existingSong.url)
            } catch {
                print("Failed to remove existing song file: \(error)")
            }
            // 更新列表中的歌曲
            songs[existingIndex] = song
        } else {
            // 如果不存在，添加新歌曲
            songs.append(song)
        }
        saveSongs()
    }
    
    func removeSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        // 删除文件
        do {
            try FileManager.default.removeItem(at: song.url)
        } catch {
            print("Failed to remove song file: \(error)")
        }
        saveSongs()
    }
    
    func updateSong(_ song: Song) {
        if let index = songs.firstIndex(where: { $0.id == song.id }) {
            songs[index] = song
            saveSongs()
        }
    }
    
    // MARK: - Persistence
    private func saveSongs() {
        if let encoded = try? JSONEncoder().encode(songs) {
            userDefaults.set(encoded, forKey: "savedSongs")
        }
    }
    
    private func loadSongs() {
        if let savedSongs = userDefaults.data(forKey: "savedSongs"),
           let decodedSongs = try? JSONDecoder().decode([Song].self, from: savedSongs) {
            // 验证文件是否存在
            songs = decodedSongs.filter { FileManager.default.fileExists(atPath: $0.url.path) }
            // 如果有歌曲被过滤掉了，保存更新后的列表
            if songs.count != decodedSongs.count {
                saveSongs()
            }
        }
    }
    
    // MARK: - Navigation Methods
    func getNextSong(after currentSong: Song) -> Song? {
        guard let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) else {
            return nil
        }
        
        let nextIndex = currentIndex + 1
        if nextIndex < songs.count {
            return songs[nextIndex]
        } else if !songs.isEmpty {
            // 如果是最后一首，返回第一首
            return songs[0]
        }
        return nil
    }
    
    func getPreviousSong(before currentSong: Song) -> Song? {
        guard let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) else {
            return nil
        }
        
        let previousIndex = currentIndex - 1
        if previousIndex >= 0 {
            return songs[previousIndex]
        } else if !songs.isEmpty {
            // 如果是第一首，返回最后一首
            return songs[songs.count - 1]
        }
        return nil
    }
} 