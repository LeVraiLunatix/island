import ImageIO
import SwiftUI
import UIKit

@MainActor
final class AnimatedGIFLoader: ObservableObject {
    @Published private(set) var frames: [UIImage] = []
    @Published private(set) var frameDelays: [Double] = []
    @Published private(set) var isLoading = false

    func load(url: URL) async {
        guard frames.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        guard let (data, _) = try? await URLSession.shared.data(from: url),
              let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return
        }

        let count = CGImageSourceGetCount(source)
        var images: [UIImage] = []
        var delays: [Double] = []
        images.reserveCapacity(count)
        delays.reserveCapacity(count)

        for index in 0..<count {
            guard let cgImage = CGImageSourceCreateImageAtIndex(source, index, nil) else { continue }
            images.append(UIImage(cgImage: cgImage))
            delays.append(Self.frameDelay(source: source, index: index))
        }

        frames = images
        frameDelays = delays
    }

    private static func frameDelay(source: CGImageSource, index: Int) -> Double {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(source, index, nil) as? [CFString: Any],
              let gifProperties = properties[kCGImagePropertyGIFDictionary] as? [CFString: Any] else {
            return 0.1
        }
        let unclamped = gifProperties[kCGImagePropertyGIFUnclampedDelayTime] as? Double
        let clamped = gifProperties[kCGImagePropertyGIFDelayTime] as? Double
        let delay = unclamped ?? clamped ?? 0.1
        return delay > 0.02 ? delay : 0.1
    }
}

/// Plays an animated GIF (or shows a static image for any other format) from
/// a remote URL. SwiftUI's AsyncImage only ever decodes a single frame, so
/// this exists specifically to make animated wallpaper previews move.
struct AnimatedImage: View {
    let url: URL?
    var contentMode: ContentMode = .fill

    @StateObject private var loader = AnimatedGIFLoader()
    @State private var frameIndex = 0

    var body: some View {
        Group {
            if let image = currentImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if loader.isLoading {
                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .overlay { ProgressView().tint(.white) }
            } else {
                Rectangle().fill(Color.white.opacity(0.08))
            }
        }
        .task(id: url) {
            frameIndex = 0
            guard let url else { return }
            await loader.load(url: url)
            await animate()
        }
    }

    private var currentImage: UIImage? {
        guard !loader.frames.isEmpty else { return nil }
        return loader.frames[min(frameIndex, loader.frames.count - 1)]
    }

    private func animate() async {
        guard loader.frames.count > 1 else { return }
        while !Task.isCancelled {
            let delay = loader.frameDelays[frameIndex]
            try? await Task.sleep(for: .seconds(delay))
            if Task.isCancelled { return }
            frameIndex = (frameIndex + 1) % loader.frames.count
        }
    }
}
