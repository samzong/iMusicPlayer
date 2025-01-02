import SwiftUI

struct SongListView: View {
    @ObservedObject var viewModel: SongListViewModel
    @EnvironmentObject var playerService: PlayerService
    @State private var showingURLInput = false
    
    var body: some View {
        NavigationView {
            VStack {
                if !viewModel.downloadProgress.isEmpty {
                    Text(viewModel.downloadProgress)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                
                if viewModel.songs.isEmpty {
                    // 空状态
                    VStack(spacing: 20) {
                        Image(systemName: "music.note.list")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("没有歌曲")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Button(action: { showingURLInput = true }) {
                            Label("添加音乐", systemImage: "plus")
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding()
                } else {
                    // 歌曲列表
                    List {
                        ForEach(viewModel.songs) { song in
                            SongRow(
                                song: song,
                                isPlaying: playerService.currentSong?.id == song.id,
                                onPlay: { viewModel.playSong(song) }
                            )
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    viewModel.removeSong(song)
                                } label: {
                                    Label("删除", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(PlainListStyle())
                }
                
                if let error = viewModel.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.caption)
                        .padding()
                }
            }
            .navigationTitle("音乐库")
            .navigationBarItems(
                trailing: Button(action: { showingURLInput = true }) {
                    Image(systemName: "plus")
                }
            )
            .sheet(isPresented: $showingURLInput) {
                NavigationView {
                    VStack(spacing: 20) {
                        TextField("输入音乐列表URL", text: $viewModel.downloadURL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .padding()
                        
                        Text("每行一个 MP3 文件地址")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if viewModel.downloadURL.isEmpty {
                            Button(action: viewModel.downloadSampleMusic) {
                                Text("使用示例音乐")
                                    .foregroundColor(.blue)
                            }
                            .padding(.top)
                        }
                        
                        Spacer()
                    }
                    .padding(.top)
                    .navigationTitle("添加音乐")
                    .navigationBarItems(
                        leading: Button("取消") {
                            showingURLInput = false
                            viewModel.downloadURL = ""
                            viewModel.errorMessage = nil
                        },
                        trailing: Button("下载") {
                            viewModel.downloadFromURL()
                            showingURLInput = false
                        }
                        .disabled(viewModel.downloadURL.isEmpty)
                    )
                }
            }
        }
    }
} 