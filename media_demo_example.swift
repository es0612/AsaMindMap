import SwiftUI
import MindMapCore
import MindMapUI

// MARK: - Media Functionality Demo
// This demonstrates the complete media functionality implementation

struct MediaFunctionalityDemo: View {
    @StateObject private var viewModel: MindMapViewModel
    @State private var selectedNode: Node?
    
    init() {
        let container = DIContainer.configure()
        self._viewModel = StateObject(wrappedValue: MindMapViewModel(container: container))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AsaMindMap Media Functionality Demo")
                .font(.title)
                .padding()
            
            // Node with Media Display
            if let node = selectedNode {
                NodeView(
                    node: node,
                    isSelected: true,
                    isEditing: false,
                    isFocused: true,
                    isFocusMode: false,
                    media: viewModel.getMediaForNode(node.id),
                    onAddMedia: {
                        viewModel.showMediaPicker(for: node.id)
                    },
                    onMediaTap: { media in
                        print("Media tapped: \(media.type.displayName)")
                    },
                    onRemoveMedia: { media in
                        viewModel.removeMediaFromNode(media, nodeID: node.id)
                    }
                )
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Demo Actions
            VStack(spacing: 12) {
                Button("Create Demo Node") {
                    createDemoNode()
                }
                .buttonStyle(.borderedProminent)
                
                Button("Add Sample Image") {
                    addSampleImage()
                }
                .buttonStyle(.bordered)
                .disabled(selectedNode == nil)
                
                Button("Add Sample Link") {
                    addSampleLink()
                }
                .buttonStyle(.bordered)
                .disabled(selectedNode == nil)
                
                Button("Show Media Picker") {
                    if let node = selectedNode {
                        viewModel.showMediaPicker(for: node.id)
                    }
                }
                .buttonStyle(.bordered)
                .disabled(selectedNode == nil)
            }
            
            Spacer()
        }
        .padding()
        .sheet(isPresented: $viewModel.showingMediaPicker) {
            if let nodeID = viewModel.mediaPickerNodeID {
                MediaPickerView(
                    isPresented: $viewModel.showingMediaPicker,
                    onMediaSelected: { result in
                        viewModel.addMediaToNode(result, nodeID: nodeID)
                    }
                )
            }
        }
        .onAppear {
            viewModel.createNewMindMap(title: "Media Demo")
        }
    }
    
    // MARK: - Demo Actions
    
    private func createDemoNode() {
        let node = Node(
            id: UUID(),
            text: "Demo Node with Media",
            position: CGPoint(x: 200, y: 200)
        )
        
        // Add to viewModel (in real implementation, this would go through use cases)
        viewModel.nodes.append(node)
        selectedNode = node
        
        // Load any existing media for this node
        viewModel.loadMediaForNode(node.id)
    }
    
    private func addSampleImage() {
        guard let node = selectedNode else { return }
        
        // Create sample image data
        let sampleImageData = createSampleImageData()
        
        let result = MediaPickerResult(
            type: .image,
            data: sampleImageData,
            fileName: "sample.jpg",
            mimeType: "image/jpeg"
        )
        
        viewModel.addMediaToNode(result, nodeID: node.id)
    }
    
    private func addSampleLink() {
        guard let node = selectedNode else { return }
        
        let result = MediaPickerResult(
            type: .link,
            url: "https://example.com"
        )
        
        viewModel.addMediaToNode(result, nodeID: node.id)
    }
    
    private func createSampleImageData() -> Data {
        // Create a simple colored rectangle as sample image data
        let size = CGSize(width: 100, height: 100)
        let renderer = UIGraphicsImageRenderer(size: size)
        
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            
            UIColor.white.setFill()
            let textRect = CGRect(x: 10, y: 40, width: 80, height: 20)
            "Sample".draw(in: textRect, withAttributes: [
                .foregroundColor: UIColor.white,
                .font: UIFont.systemFont(ofSize: 12)
            ])
        }
        
        return image.jpegData(compressionQuality: 0.8) ?? Data()
    }
}

// MARK: - Media Use Case Demo
struct MediaUseCaseDemo {
    
    static func demonstrateMediaWorkflow() async {
        print("🎯 Media Functionality Demonstration")
        
        // Setup
        let nodeRepository = InMemoryNodeRepository()
        let mediaRepository = InMemoryMediaRepository()
        
        // Create test node
        let nodeID = UUID()
        let node = Node(id: nodeID, text: "Demo Node", position: .zero)
        try? await nodeRepository.save(node)
        
        // Use Cases
        let addMediaUseCase = AddMediaToNodeUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
        
        let validateURLUseCase = ValidateMediaURLUseCase()
        let getMediaUseCase = GetNodeMediaUseCase(
            nodeRepository: nodeRepository,
            mediaRepository: mediaRepository
        )
        
        do {
            // 1. Validate URL
            print("\n1️⃣ Validating URL...")
            let urlRequest = ValidateMediaURLRequest(url: "example.com", mediaType: .link)
            let urlResponse = try await validateURLUseCase.execute(urlRequest)
            print("   ✅ URL valid: \(urlResponse.isValid)")
            print("   📝 Normalized: \(urlResponse.normalizedURL ?? "none")")
            
            // 2. Add Image
            print("\n2️⃣ Adding image...")
            let imageData = "sample image data".data(using: .utf8)!
            let addImageRequest = AddMediaToNodeRequest(
                nodeID: nodeID,
                mediaType: .image,
                data: imageData,
                fileName: "demo.jpg",
                mimeType: "image/jpeg"
            )
            
            let imageResponse = try await addMediaUseCase.execute(addImageRequest)
            print("   ✅ Image added: \(imageResponse.media.id)")
            
            // 3. Add Link
            print("\n3️⃣ Adding link...")
            let addLinkRequest = AddMediaToNodeRequest(
                nodeID: nodeID,
                mediaType: .link,
                url: urlResponse.normalizedURL
            )
            
            let linkResponse = try await addMediaUseCase.execute(addLinkRequest)
            print("   ✅ Link added: \(linkResponse.media.id)")
            
            // 4. Get All Media
            print("\n4️⃣ Retrieving media...")
            let getMediaRequest = GetNodeMediaRequest(nodeID: nodeID)
            let mediaResponse = try await getMediaUseCase.execute(getMediaRequest)
            print("   ✅ Found \(mediaResponse.media.count) media items:")
            
            for media in mediaResponse.media {
                print("      - \(media.type.displayName): \(media.displayName)")
            }
            
            print("\n🎉 Media functionality demonstration completed!")
            
        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview
#if DEBUG
struct MediaFunctionalityDemo_Previews: PreviewProvider {
    static var previews: some View {
        MediaFunctionalityDemo()
    }
}
#endif