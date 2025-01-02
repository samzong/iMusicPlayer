import SwiftUI

@main
struct iMusicPlayerApp: App {
    // 依赖注入
    @StateObject private var playerService = PlayerService.shared
    @StateObject private var songService = SongService.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(playerService)
                .environmentObject(songService)
        }
    }
} 