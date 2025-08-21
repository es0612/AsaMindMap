import SwiftUI
import MindMapCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Media Display View
@available(iOS 16.0, *)
public struct MediaDisplayView: View {
    
    // MARK: - Properties
    let media: [Media]
    let maxDisplayCount: Int
    let onMediaTap: ((Media) -> Void)?
    let onRemoveMedia: ((Media) -> Void)?
    
    @State private var showingAllMedia = false
    
    // MARK: - Initialization
    public init(
        media: [Media],
        maxDisplayCount: Int = 3,
        onMediaTap: ((Media) -> Void)? = nil,
        onRemoveMedia: ((Media) -> Void)? = nil
    ) {
        self.media = media
        self.maxDisplayCount = maxDisplayCount
        self.onMediaTap = onMediaTap
        self.onRemoveMedia = onRemoveMedia
    }
    
    // MARK: - Body
    public var body: some View {
        if !media.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                mediaGrid
                
                if media.count > maxDisplayCount {
                    moreMediaButton
                }
            }
            .sheet(isPresented: $showingAllMedia) {
                allMediaView
            }
        }
    }
    
    // MARK: - Media Grid
    private var mediaGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: min(3, maxDisplayCount)), spacing: 4) {
            ForEach(Array(media.prefix(maxDisplayCount).enumerated()), id: \.element.id) { index, mediaItem in
                MediaThumbnailView(
                    media: mediaItem,
                    size: thumbnailSize(for: index),
                    onTap: {
                        onMediaTap?(mediaItem)
                    },
                    onRemove: onRemoveMedia != nil ? {
                        onRemoveMedia?(mediaItem)
                    } : nil
                )
            }
        }
    }
    
    // MARK: - More Media Button
    private var moreMediaButton: some View {
        Button(action: {
            showingAllMedia = true
        }) {
            HStack(spacing: 4) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 12))
                
                Text("他\(media.count - maxDisplayCount)件")
                    .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(.blue)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - All Media View
    private var allMediaView: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 12) {
                    ForEach(media, id: \.id) { mediaItem in
                        MediaThumbnailView(
                            media: mediaItem,
                            size: CGSize(width: 100, height: 100),
                            onTap: {
                                onMediaTap?(mediaItem)
                            },
                            onRemove: onRemoveMedia != nil ? {
                                onRemoveMedia?(mediaItem)
                            } : nil
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("添付メディア")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        showingAllMedia = false
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("完了") {
                        showingAllMedia = false
                    }
                }
                #endif
            }
        }
    }
    
    // MARK: - Private Methods
    private func thumbnailSize(for index: Int) -> CGSize {
        switch media.count {
        case 1:
            return CGSize(width: 60, height: 60)
        case 2:
            return CGSize(width: 45, height: 45)
        default:
            return CGSize(width: 30, height: 30)
        }
    }
}

// MARK: - Media Thumbnail View
@available(iOS 16.0, *)
private struct MediaThumbnailView: View {
    let media: Media
    let size: CGSize
    let onTap: (() -> Void)?
    let onRemove: (() -> Void)?
    
    @State private var showingRemoveConfirmation = false
    
    var body: some View {
        Button(action: {
            onTap?()
        }) {
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: size.width, height: size.height)
                
                // Content
                Group {
                    switch media.type {
                    case .image:
                        imageContent
                    case .link:
                        linkContent
                    case .sticker:
                        stickerContent
                    case .document:
                        documentContent
                    case .audio:
                        audioContent
                    case .video:
                        videoContent
                    }
                }
                
                // Remove button
                if onRemove != nil {
                    VStack {
                        HStack {
                            Spacer()
                            Button(action: {
                                showingRemoveConfirmation = true
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(.red)
                                    .background(Color.white, in: Circle())
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        Spacer()
                    }
                    .padding(2)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog(
            "メディアを削除",
            isPresented: $showingRemoveConfirmation,
            titleVisibility: .visible
        ) {
            Button("削除", role: .destructive) {
                onRemove?()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("このメディアをノードから削除しますか？")
        }
    }
    
    // MARK: - Content Views
    @ViewBuilder
    private var imageContent: some View {
        #if canImport(UIKit)
        if let thumbnailData = media.thumbnailData,
           let uiImage = UIImage(data: thumbnailData) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .cornerRadius(6)
        } else if let data = media.data,
                  let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: size.width, height: size.height)
                .clipped()
                .cornerRadius(6)
        } else {
            Image(systemName: "photo")
                .font(.system(size: size.width * 0.4))
                .foregroundColor(.gray)
        }
        #else
        Image(systemName: "photo")
            .font(.system(size: size.width * 0.4))
            .foregroundColor(.gray)
        #endif
    }
    
    @ViewBuilder
    private var linkContent: some View {
        VStack(spacing: 2) {
            Image(systemName: "link")
                .font(.system(size: size.width * 0.3))
                .foregroundColor(.blue)
            
            if size.width > 40 {
                Text("リンク")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.blue)
            }
        }
    }
    
    @ViewBuilder
    private var stickerContent: some View {
        VStack(spacing: 2) {
            Image(systemName: "face.smiling")
                .font(.system(size: size.width * 0.3))
                .foregroundColor(.purple)
            
            if size.width > 40 {
                Text("ステッカー")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.purple)
            }
        }
    }
    
    @ViewBuilder
    private var documentContent: some View {
        VStack(spacing: 2) {
            Image(systemName: "doc")
                .font(.system(size: size.width * 0.3))
                .foregroundColor(.orange)
            
            if size.width > 40 {
                Text("文書")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.orange)
            }
        }
    }
    
    @ViewBuilder
    private var audioContent: some View {
        VStack(spacing: 2) {
            Image(systemName: "waveform")
                .font(.system(size: size.width * 0.3))
                .foregroundColor(.green)
            
            if size.width > 40 {
                Text("音声")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.green)
            }
        }
    }
    
    @ViewBuilder
    private var videoContent: some View {
        VStack(spacing: 2) {
            Image(systemName: "play.rectangle")
                .font(.system(size: size.width * 0.3))
                .foregroundColor(.red)
            
            if size.width > 40 {
                Text("動画")
                    .font(.system(size: 8, weight: .medium))
                    .foregroundColor(.red)
            }
        }
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 16.0, *)
struct MediaDisplayView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Single image
            MediaDisplayView(
                media: [
                    Media(type: .image, fileName: "test.jpg")
                ]
            )
            
            // Multiple media
            MediaDisplayView(
                media: [
                    Media(type: .image, fileName: "image1.jpg"),
                    Media(type: .link, url: "https://example.com"),
                    Media(type: .document, fileName: "document.pdf"),
                    Media(type: .audio, fileName: "audio.mp3"),
                    Media(type: .video, fileName: "video.mp4")
                ]
            )
        }
        .padding()
    }
}
#endif