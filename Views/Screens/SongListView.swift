import SwiftUI

struct SongListView: View {
    @ObservedObject var viewModel: SongListViewModel
    @EnvironmentObject var playerService: PlayerService
    @State private var showingURLInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // 下载进度
                if !viewModel.downloadProgress.isEmpty {
                    ProgressView(viewModel.downloadProgress)
                        .padding()
                }
                
                // 主内容
                if viewModel.songs.isEmpty {
                    EmptyStateView(showURLInput: $showingURLInput)
                } else {
                    SongListContentView(
                        songs: viewModel.songs,
                        currentSong: playerService.currentSong,
                        onPlay: viewModel.playSong,
                        onDelete: viewModel.removeSong
                    )
                }
            }
            .navigationTitle("音乐库")
            .navigationBarItems(trailing: addButton)
            .sheet(isPresented: $showingURLInput) {
                AddMusicSheet(
                    isPresented: $showingURLInput,
                    downloadURL: $viewModel.downloadURL,
                    onDownload: viewModel.downloadFromURL
                )
            }
        }
    }
    
    private var addButton: some View {
        Button(action: { showingURLInput = true }) {
            Image(systemName: "plus")
        }
    }
}

// MARK: - 子视图
private struct EmptyStateView: View {
    @Binding var showURLInput: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "music.note.list")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("没有歌曲")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button(action: { showURLInput = true }) {
                Label("添加音乐", systemImage: "plus")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
    }
}

private struct SongListContentView: View {
    let songs: [Song]
    let currentSong: Song?
    let onPlay: (Song) -> Void
    let onDelete: (Song) -> Void
    
    var body: some View {
        List {
            ForEach(songs) { song in
                SongRow(
                    song: song,
                    isPlaying: currentSong?.id == song.id,
                    onPlay: { onPlay(song) }
                )
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        onDelete(song)
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

private struct AddMusicSheet: View {
    @Binding var isPresented: Bool
    @Binding var downloadURL: String
    let onDownload: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("输入音乐列表URL", text: $downloadURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .padding()
                
                Text("每行一个 MP3 文件地址")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if downloadURL.isEmpty {
                    Button {
                        downloadURL = "https://img.samzong.me/m.txt"
                        onDownload()
                        isPresented = false
                    } label: {
                        Label("使用示例音乐", systemImage: "music.note")
                            .foregroundColor(.blue)
                    }
                    .padding(.top)
                }
                
                Spacer()
            }
            .padding(.top)
            .navigationTitle("添加音乐")
            .navigationBarItems(
                leading: cancelButton,
                trailing: downloadButton
            )
        }
    }
    
    private var cancelButton: some View {
        Button("取消") {
            downloadURL = ""
            isPresented = false
        }
    }
    
    private var downloadButton: some View {
        Button("下载") {
            onDownload()
            isPresented = false
        }
        .disabled(downloadURL.isEmpty)
    }
} 