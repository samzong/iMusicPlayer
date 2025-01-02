import Foundation
import Combine

class SongListViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var downloadProgress: String = ""
    @Published var downloadURL: String = ""
    
    private var songService: SongService
    private var playerService: PlayerService
    private var cancellables = Set<AnyCancellable>()
    private var downloadQueue: [String] = []
    private var isProcessingQueue = false
    
    init(songService: SongService = .shared, playerService: PlayerService = .shared) {
        self.songService = songService
        self.playerService = playerService
        setupBindings()
    }
    
    private func setupBindings() {
        songService.$songs
            .assign(to: &$songs)
    }
    
    // MARK: - Download Methods
    func downloadFromURL() {
        guard let url = URL(string: downloadURL) else {
            downloadProgress = "无效的URL"
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.downloadProgress = ""
            }
            return
        }
        
        downloadProgress = "正在获取音乐列表..."
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let content = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self?.downloadProgress = "获取音乐列表失败"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self?.downloadProgress = ""
                    }
                }
                return
            }
            
            let urls = content.components(separatedBy: .newlines)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
                .filter { $0.hasPrefix("https://") }  // 只接受 https 链接
                .filter { $0.hasSuffix(".mp3") }     // 只接受 mp3 文件
            
            DispatchQueue.main.async {
                if urls.isEmpty {
                    self.downloadProgress = "没有找到有效的音乐文件"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.downloadProgress = ""
                    }
                    return
                }
                
                self.downloadQueue = urls
                self.downloadProgress = "准备下载 \(urls.count) 个文件"
                self.processNextInQueue()
            }
        }.resume()
    }
    
    private func processNextInQueue() {
        guard !isProcessingQueue, let url = downloadQueue.first else {
            if downloadQueue.isEmpty {
                downloadProgress = "所有下载已完成"
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    self.downloadProgress = ""
                }
            }
            return
        }
        
        isProcessingQueue = true
        downloadQueue.removeFirst()
        
        guard let downloadURL = URL(string: url) else {
            isProcessingQueue = false
            processNextInQueue()
            return
        }
        
        let fileName = downloadURL.lastPathComponent
        let title = fileName.replacingOccurrences(of: ".mp3", with: "")
        
        // 检查是否已存在同名歌曲
        if songs.contains(where: { $0.title == title }) {
            print("跳过已存在的歌曲: \(title)")
            downloadProgress = "跳过已存在的歌曲: \(title)"
            isProcessingQueue = false
            processNextInQueue()
            return
        }
        
        downloadProgress = "正在下载: \(fileName)"
        
        let downloadTask = URLSession.shared.downloadTask(with: downloadURL) { [weak self] tempURL, response, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    print("下载失败: \(error.localizedDescription)")
                    self.downloadProgress = "下载失败: \(fileName)"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                }
                return
            }
            
            guard let tempURL = tempURL else {
                DispatchQueue.main.async {
                    print("下载失败: 没有临时文件")
                    self.downloadProgress = "下载失败: \(fileName)"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                }
                return
            }
            
            // 创建一个新的临时文件位置
            let tempDir = FileManager.default.temporaryDirectory
            let tempFile = tempDir.appendingPathComponent(fileName)
            
            do {
                // 如果已存在，先删除
                if FileManager.default.fileExists(atPath: tempFile.path) {
                    try FileManager.default.removeItem(at: tempFile)
                }
                
                // 移动文件到新的临时位置
                try FileManager.default.moveItem(at: tempURL, to: tempFile)
                
                DispatchQueue.main.async {
                    self.songService.addSong(tempFile)
                    self.downloadProgress = "已添加: \(title)"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                }
            } catch {
                print("处理文件失败: \(error)")
                DispatchQueue.main.async {
                    self.downloadProgress = "处理失败: \(fileName)"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                }
            }
        }
        
        downloadTask.resume()
    }
    
    // MARK: - Public Methods
    func playSong(_ song: Song) {
        playerService.playSong(song)
    }
    
    func removeSong(_ song: Song) {
        songService.removeSong(song)
    }
} 