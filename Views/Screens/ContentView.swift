import SwiftUI

struct ContentView: View {
    @StateObject private var playerViewModel = PlayerViewModel()
    @StateObject private var songListViewModel = SongListViewModel()
    
    var body: some View {
        TabView {
            // 播放器页面
            PlayerView(viewModel: playerViewModel)
                .tabItem {
                    Label("播放", systemImage: "play.circle.fill")
                }
            
            // 歌曲列表页面
            SongListView(viewModel: songListViewModel)
                .tabItem {
                    Label("音乐库", systemImage: "music.note.list")
                }
        }
    }
} 