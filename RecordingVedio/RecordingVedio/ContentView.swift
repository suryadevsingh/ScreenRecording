
// MARK: -- Screen Recording
import SwiftUI
import ReplayKit
import Photos
import AVKit

struct ContentView: View {
    @State private var isRecording = false
    @State private var previewVideoURL: URL?
    @State private var showPreview = false
    
    var body: some View {
        VStack(spacing: 20) {
            if isRecording {
                Text("Recording...").foregroundColor(.red)
            } else {
                Text("Not recording")
            }
            
            Button(action: toggleRecording) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
            }
            
            if let _ = previewVideoURL {
                Button(action: {
                    showPreview = true
                }) {
                    Text("Preview Recording")
                }
                .sheet(isPresented: $showPreview) {
                    VideoPlayer(url: previewVideoURL!)
                }
            }
        }
        .padding()
    }
    
    func toggleRecording() {
        let recorder = RPScreenRecorder.shared()
        if isRecording {
            recorder.stopRecording { (previewVC, error) in
                guard let previewVC = previewVC else { return }
                previewVC.previewControllerDelegate = self.makeCoordinator()
                self.present(previewVC, animated: true, completion: nil)
                self.isRecording = false
            }
        } else {
            recorder.startRecording { (error) in
                if error == nil {
                    self.isRecording = true
                }
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, RPPreviewViewControllerDelegate {
        var parent: ContentView
        
        init(_ parent: ContentView) {
            self.parent = parent
        }
        
        func previewControllerDidFinish(_ previewController: RPPreviewViewController) {
            previewController.dismiss(animated: true) {
                // After dismissal, get the last saved video from Photos
                self.fetchLatestVideo()
            }
        }
        
        func fetchLatestVideo() {
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            fetchOptions.fetchLimit = 1
            let fetchResult = PHAsset.fetchAssets(with: .video, options: fetchOptions)
            if let asset = fetchResult.firstObject {
                PHCachingImageManager().requestAVAsset(forVideo: asset, options: nil) { (avAsset, _, _) in
                    if let urlAsset = avAsset as? AVURLAsset {
                        DispatchQueue.main.async {
                            self.parent.previewVideoURL = urlAsset.url
                        }
                    }
                }
            }
        }
    }
    
    func present(_ viewControllerToPresent: UIViewController, animated: Bool, completion: (() -> Void)?) {
        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(viewControllerToPresent, animated: animated, completion: completion)
        }
    }
}

struct VideoPlayer: View {
    var url: URL
    private var player: AVPlayer { AVPlayer(url: url) }
    
    var body: some View {
        AVPlayerViewControllerRepresentable(player: player)
    }
}

struct AVPlayerViewControllerRepresentable: UIViewControllerRepresentable {
    var player: AVPlayer

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = player
        return controller
    }
    
    func updateUIViewController(_ uiViewController: AVPlayerViewController, context: Context) {
        // No updates needed as the player remains the same
    }
}


