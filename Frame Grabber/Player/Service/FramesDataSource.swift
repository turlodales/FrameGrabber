import AVKit

class FramesDataSource {

    let video: Video
    var thumbnailSize: CGSize = .zero
    /// Kept sorted by time.
    private(set) var thumbnails = [Frame]()

    private lazy var frameGenerator: AVAssetImageGenerator = {
        let generator = AVAssetImageGenerator(asset: video.avAsset)
        generator.requestedTimeToleranceBefore = .zero
        generator.requestedTimeToleranceAfter = .zero
        generator.appliesPreferredTrackTransform = true
        return generator
    }()

    init(video: Video) {
        self.video = video
    }

    deinit {
        cancelFrameGeneration()
    }

    func cancelFrameGeneration() {
        frameGenerator.cancelAllCGImageGeneration()
    }

    // MARK: Thumbnails

    private var frameGeneratorThumbnailSize: CGSize {
        return video.pixelSize.aspectFilling(thumbnailSize).scaledToScreen
    }

    /// In case of success, returns the index the thumbnail was inserted in.
    func addThumbnail(for time: CMTime, completionHandler: @escaping (Int?, FramesResult) -> ()) {
        frameGenerator.maximumSize = frameGeneratorThumbnailSize

        frameGenerator.generateFrames(for: [time]) { [weak self] result in
            let index = result.frames.first.flatMap { self?.addThumbnail($0) }
            completionHandler(index, result)
        }
    }

    func addThumbnail(_ frame: Frame) -> Int {
        let index = insertionIndex(for: frame)
        thumbnails.insert(frame, at: index)
        return index
    }

    func removeThumbnail(at index: Int) {
        thumbnails.remove(at: index)
    }

    private func insertionIndex(for frame: Frame) -> Int {
        return thumbnails.firstIndex { frame.actualTime < $0.actualTime } ?? thumbnails.count
    }

    // MARK: Full-Size Frames

    /// Adds image metadata from the video.
    func generateFullSizeFrames(for times: [CMTime], completionHandler: @escaping (FramesResult) -> ()) {
        frameGenerator.maximumSize = .zero
        frameGenerator.generateFrames(for: times, metadata: video.metadata, completionHandler: completionHandler)
    }
}
