import Foundation
import Combine

class SongListViewModel: ObservableObject {
    @Published var songs: [Song] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var downloadProgress: String = ""
    @Published var downloadURL: String = ""
    
    private var songService: SongService
    private var playerService: PlayerService
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    private var downloadQueue: [String] = []
    private var isProcessingQueue = false
    
    private let sampleMusicListURL = "https://img.samzong.me/m.txt"
    
    init(songService: SongService = .shared, playerService: PlayerService = .shared) {
        self.songService = songService
        self.playerService = playerService
        
        setupBindings()
        setupDownloadsDirectory()
    }
    
    private func setupBindings() {
        songService.$songs
            .assign(to: &$songs)
    }
    
    private func setupDownloadsDirectory() {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { 
            print("无法获取文档目录")
            return 
        }
        
        let downloadsPath = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
        print("下载目录路径: \(downloadsPath.path)")
        
        do {
            if !fileManager.fileExists(atPath: downloadsPath.path) {
                try fileManager.createDirectory(at: downloadsPath, withIntermediateDirectories: true, attributes: nil)
                print("创建下载目录成功")
            } else {
                print("下载目录已存在")
            }
        } catch {
            print("创建下载目录失败: \(error)")
        }
    }
    
    private func getDownloadsDirectory() -> URL? {
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentsPath.appendingPathComponent("Downloads", isDirectory: true)
    }
    
    // MARK: - Download Methods
    func downloadFromURL() {
        guard let url = URL(string: downloadURL) else {
            errorMessage = "无效的URL"
            return
        }
        
        downloadProgress = "正在获取音乐列表..."
        print("开始从 \(url) 获取音乐列表")
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                if let error = error {
                    self.errorMessage = "获取音乐列表失败: \(error.localizedDescription)"
                    return
                }
                
                guard let data = data,
                      let content = String(data: data, encoding: .utf8) else {
                    self.errorMessage = "无法读取音乐列表"
                    return
                }
                
                print("获取到的原始内容：\n\(content)")
                
                let urls = content.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                    .filter { $0.hasPrefix("https://") }  // 只保留 https 链接
                
                print("解析后的URL列表（仅 HTTPS）：")
                urls.forEach { print($0) }
                
                self.downloadQueue = urls
                self.downloadProgress = "准备下载 \(urls.count) 个文件"
                self.processNextInQueue()
            }
        }.resume()
    }
    
    func downloadSampleMusic() {
        downloadURL = sampleMusicListURL
        downloadFromURL()
    }
    
    private func processNextInQueue() {
        guard !isProcessingQueue else { 
            print("当前有下载任务正在进行，等待...")
            return 
        }
        guard !downloadQueue.isEmpty else {
            downloadProgress = "所有下载已完成"
            isProcessingQueue = false
            print("下载队列已清空，所有任务完成")
            return
        }
        
        isProcessingQueue = true
        let url = downloadQueue[0]
        downloadQueue.removeFirst()
        
        print("处理下一个URL: \(url)")
        print("剩余队列数量: \(downloadQueue.count)")
        
        guard let downloadURL = URL(string: url) else {
            downloadProgress = "跳过无效URL: \(url)"
            isProcessingQueue = false
            processNextInQueue()
            return
        }
        
        let fileName = downloadURL.lastPathComponent
        if !fileName.hasSuffix(".mp3") {
            downloadProgress = "跳过非MP3文件: \(fileName)"
            isProcessingQueue = false
            processNextInQueue()
            return
        }
        
        // 检查是否存在同名歌曲
        let title = fileName.replacingOccurrences(of: ".mp3", with: "")
        if songs.contains(where: { $0.title == title }) {
            print("跳过已存在的歌曲: \(title)")
            downloadProgress = "跳过已存在的歌曲: \(title)"
            isProcessingQueue = false
            processNextInQueue()
            return
        }
        
        // 确保下载目录存在
        guard let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            errorMessage = "无法访问文档目录"
            isProcessingQueue = false
            return
        }
        
        let downloadsDir = documentsPath.appendingPathComponent("Downloads", isDirectory: true)
        
        // 创建目标URL
        let destinationURL = downloadsDir.appendingPathComponent(fileName)
        print("目标文件路径: \(destinationURL.path)")
        
        print("开始下载: \(fileName)")
        downloadProgress = "正在下载: \(fileName) (剩余: \(downloadQueue.count))"
        
        // 使用 dataTask 直接下载数据
        URLSession.shared.dataTask(with: downloadURL) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let error = error {
                    print("下载失败: \(fileName) - \(error.localizedDescription)")
                    self.downloadProgress = "下载失败: \(fileName) - \(error.localizedDescription)"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                    return
                }
                
                guard let data = data else {
                    print("下载失败: 没有接收到数据")
                    self.downloadProgress = "下载失败: 没有接收到数据"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                    return
                }
                
                do {
                    // 确保下载目录存在
                    if !self.fileManager.fileExists(atPath: downloadsDir.path) {
                        try self.fileManager.createDirectory(at: downloadsDir, withIntermediateDirectories: true, attributes: nil)
                        print("创建下载目录: \(downloadsDir.path)")
                    }
                    
                    // 如果目标文件已存在，先删除
                    if self.fileManager.fileExists(atPath: destinationURL.path) {
                        try self.fileManager.removeItem(at: destinationURL)
                        print("删除已存在的文件: \(destinationURL.path)")
                    }
                    
                    // 直接写入数据到目标文件
                    try data.write(to: destinationURL)
                    print("文件已保存到: \(destinationURL.path)")
                    
                    // 创建新的Song对象
                    let song = Song(
                        title: title,
                        url: destinationURL
                    )
                    
                    // 添加到歌曲列表
                    self.songService.addSong(song)
                    print("歌曲已添加到列表: \(title)")
                    self.downloadProgress = "下载完成: \(fileName)"
                    
                    // 继续下载队列中的下一个
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                } catch {
                    print("保存失败: \(fileName) - \(error)")
                    self.downloadProgress = "保存失败: \(fileName) - \(error.localizedDescription)"
                    self.isProcessingQueue = false
                    self.processNextInQueue()
                }
            }
        }.resume()
    }
    
    // MARK: - Public Methods
    func playSong(_ song: Song) {
        playerService.playSong(song)
        NotificationCenter.default.post(name: NSNotification.Name("SongPlayed"), object: song)
    }
    
    func removeSong(_ song: Song) {
        songService.removeSong(song)
    }
} 