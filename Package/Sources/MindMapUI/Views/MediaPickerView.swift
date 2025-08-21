import SwiftUI
import PhotosUI
import MindMapCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Media Picker View
@available(iOS 16.0, *)
public struct MediaPickerView: View {
    
    // MARK: - Properties
    @Binding var isPresented: Bool
    let onMediaSelected: (MediaPickerResult) -> Void
    
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingCamera = false
    @State private var showingLinkInput = false
    @State private var linkURL = ""
    @State private var isValidatingURL = false
    @State private var urlValidationMessage = ""
    
    // MARK: - Body
    public var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Media Options
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // Photo Library
                        MediaOptionCard(
                            icon: "photo.on.rectangle",
                            title: "フォトライブラリ",
                            subtitle: "写真を選択",
                            color: .blue
                        ) {
                            showPhotosPicker()
                        }
                        
                        // Camera
                        MediaOptionCard(
                            icon: "camera",
                            title: "カメラ",
                            subtitle: "写真を撮影",
                            color: .green
                        ) {
                            showCamera()
                        }
                        
                        // Link
                        MediaOptionCard(
                            icon: "link",
                            title: "リンク",
                            subtitle: "URLを追加",
                            color: .orange
                        ) {
                            showingLinkInput = true
                        }
                        
                        // Stickers (Premium feature placeholder)
                        MediaOptionCard(
                            icon: "face.smiling",
                            title: "ステッカー",
                            subtitle: "絵文字・ステッカー",
                            color: .purple,
                            isPremium: true
                        ) {
                            // TODO: Implement sticker picker
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("メディアを追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                #else
                ToolbarItem(placement: .primaryAction) {
                    Button("キャンセル") {
                        isPresented = false
                    }
                }
                #endif
            }
        }
        .photosPicker(
            isPresented: .constant(selectedPhotoItem != nil),
            selection: $selectedPhotoItem,
            matching: .images
        )
        #if canImport(UIKit)
        .fullScreenCover(isPresented: $showingCamera) {
            CameraView { image in
                handleCameraImage(image)
            }
        }
        #endif
        .sheet(isPresented: $showingLinkInput) {
            linkInputView
        }
        .onChange(of: selectedPhotoItem) { item in
            handlePhotoSelection(item)
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 8) {
            Text("ノードにメディアを追加")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("画像、リンク、ステッカーを追加してマインドマップを豊かにしましょう")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Link Input View
    private var linkInputView: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("URL")
                        .font(.headline)
                    
                    TextField("https://example.com", text: $linkURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        #if os(iOS)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        #endif
                    
                    if !urlValidationMessage.isEmpty {
                        Text(urlValidationMessage)
                            .font(.caption)
                            .foregroundColor(urlValidationMessage.contains("有効") ? .green : .red)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("リンクを追加")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        showingLinkInput = false
                        linkURL = ""
                        urlValidationMessage = ""
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("追加") {
                        addLink()
                    }
                    .disabled(linkURL.isEmpty || isValidatingURL)
                }
                #else
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        showingLinkInput = false
                        linkURL = ""
                        urlValidationMessage = ""
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("追加") {
                        addLink()
                    }
                    .disabled(linkURL.isEmpty || isValidatingURL)
                }
                #endif
            }
        }
        .onChange(of: linkURL) { url in
            validateURL(url)
        }
    }
    
    // MARK: - Private Methods
    private func showPhotosPicker() {
        // PhotosPicker will be triggered by the binding
    }
    
    private func showCamera() {
        showingCamera = true
    }
    
    private func handlePhotoSelection(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                let result = MediaPickerResult(
                    type: .image,
                    data: data,
                    fileName: "photo.jpg",
                    mimeType: "image/jpeg"
                )
                
                await MainActor.run {
                    onMediaSelected(result)
                    isPresented = false
                }
            }
        }
    }
    
    #if canImport(UIKit)
    private func handleCameraImage(_ image: UIImage) {
        showingCamera = false
        
        if let data = image.jpegData(compressionQuality: 0.8) {
            let result = MediaPickerResult(
                type: .image,
                data: data,
                fileName: "camera_photo.jpg",
                mimeType: "image/jpeg"
            )
            
            onMediaSelected(result)
            isPresented = false
        }
    }
    #else
    private func handleCameraImage(_ image: Any) {
        // Camera not supported on this platform
        showingCamera = false
    }
    #endif
    
    private func validateURL(_ url: String) {
        guard !url.isEmpty else {
            urlValidationMessage = ""
            return
        }
        
        isValidatingURL = true
        
        Task {
            // Simple URL validation for now
            if URL(string: url) != nil || URL(string: "https://\(url)") != nil {
                await MainActor.run {
                    urlValidationMessage = "有効なURLです"
                    isValidatingURL = false
                }
            } else {
                await MainActor.run {
                    urlValidationMessage = "無効なURL形式です"
                    isValidatingURL = false
                }
            }
        }
    }
    
    private func addLink() {
        let result = MediaPickerResult(
            type: .link,
            url: linkURL
        )
        
        onMediaSelected(result)
        showingLinkInput = false
        isPresented = false
    }
}

// MARK: - Media Option Card
@available(iOS 16.0, *)
private struct MediaOptionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let color: Color
    let isPremium: Bool
    let action: () -> Void
    
    init(
        icon: String,
        title: String,
        subtitle: String,
        color: Color,
        isPremium: Bool = false,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.color = color
        self.isPremium = isPremium
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(color)
                    
                    if isPremium {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.yellow)
                            }
                            Spacer()
                        }
                    }
                }
                
                VStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isPremium) // Disable premium features for now
    }
}

#if canImport(UIKit)
// MARK: - Camera View
@available(iOS 16.0, *)
private struct CameraView: UIViewControllerRepresentable {
    let onImageCaptured: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImageCaptured(image)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
}
#else
// MARK: - Camera View (Placeholder for non-iOS platforms)
@available(iOS 16.0, macOS 14.0, *)
private struct CameraView: View {
    let onImageCaptured: (Any) -> Void
    
    var body: some View {
        Text("Camera not available on this platform")
            .padding()
    }
}
#endif

// MARK: - Media Picker Result
public struct MediaPickerResult {
    public let type: MediaType
    public let data: Data?
    public let url: String?
    public let fileName: String?
    public let mimeType: String?
    
    public init(
        type: MediaType,
        data: Data? = nil,
        url: String? = nil,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        self.type = type
        self.data = data
        self.url = url
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

// MARK: - Preview
#if DEBUG
@available(iOS 16.0, *)
struct MediaPickerView_Previews: PreviewProvider {
    static var previews: some View {
        MediaPickerView(
            isPresented: .constant(true),
            onMediaSelected: { result in
                print("Selected media: \(result.type)")
            }
        )
    }
}
#endif