import Foundation
import Combine

class SongService: ObservableObject {
    static let shared = SongService()
    
    @Published var songs: [Song] = []
    private let userDefaults = UserDefaults.standard
    
    private init() {
        loadSongs()
    }
    
    // MARK: - Song Management
    func addSong(_ sourceURL: URL) {
        // 使用文件名作为歌曲标题
        let title = sourceURL.deletingPathExtension().lastPathComponent
        
        // 如果已存在同名歌曲，跳过
        if songs.contains(where: { $0.title == title }) {
            return
        }
        
        // 创建新歌曲
        let song = Song(title: title)
        
        // 复制文件到 Documents 目录
        do {
            if FileManager.default.fileExists(atPath: song.url.path) {
                try FileManager.default.removeItem(at: song.url)
            }
            try FileManager.default.copyItem(at: sourceURL, to: song.url)
            songs.append(song)
            saveSongs()
        } catch {
            print("添加歌曲失败: \(error)")
        }
    }
    
    func removeSong(_ song: Song) {
        songs.removeAll { $0.id == song.id }
        try? FileManager.default.removeItem(at: song.url)
        saveSongs()
    }
    
    // MARK: - Persistence
    private func saveSongs() {
        // 只保存文件仍然存在的歌曲
        songs = songs.filter { FileManager.default.fileExists(atPath: $0.url.path) }
        if let encoded = try? JSONEncoder().encode(songs) {
            userDefaults.set(encoded, forKey: "savedSongs")
        }
    }
    
    private func loadSongs() {
        if let savedSongs = userDefaults.data(forKey: "savedSongs"),
           let decodedSongs = try? JSONDecoder().decode([Song].self, from: savedSongs) {
            // 只加载文件仍然存在的歌曲
            songs = decodedSongs.filter { FileManager.default.fileExists(atPath: $0.url.path) }
        }
    }
    
    // MARK: - Navigation Methods
    func getNextSong(after currentSong: Song) -> Song? {
        guard let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) else {
            return nil
        }
        return songs[safe: currentIndex + 1] ?? songs.first
    }
    
    func getPreviousSong(before currentSong: Song) -> Song? {
        guard let currentIndex = songs.firstIndex(where: { $0.id == currentSong.id }) else {
            return nil
        }
        return songs[safe: currentIndex - 1] ?? songs.last
    }
}

// 安全数组访问
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
} 