import AVKit

enum FramesResult {
    case cancelled
    case succeeded([Frame])
    case failed

    var frames: [Frame] {
        if case .succeeded(let frames) = self { return frames }
        return []
    }

    var isCancelled: Bool {
        if case .cancelled = self { return true }
        return false
    }

    var isFailed: Bool {
        if case .failed = self { return true }
        return false
    }
}

extension AVAssetImageGenerator {

    /// Handler is called on main queue. Final result is cancelled or failed if at least
    /// one frame result is cancelled or failed.
    func generateFrames(for times: [CMTime], metadata: CGImageMetadata? = nil, completionHandler: @escaping (FramesResult) -> ()) {
        let times = times.map(NSValue.init)
        var frames = [Frame]()
        // Coalesce handler called for each requested time into single result.
        var isDone = false

        generateCGImagesAsynchronously(forTimes: times) { requestedTime, cgImage, actualTime, status, error in
            guard !isDone else { return }

            switch (status, cgImage) {

            case (.cancelled, _):
                isDone = true
                DispatchQueue.main.async { completionHandler(.cancelled) }

            case (.succeeded, let cgImage?):
                let image = MetadataImage(image: cgImage, metadata: metadata)
                let frame = Frame(image: image, requestedTime: requestedTime, actualTime: actualTime)
                frames.append(frame)

                if frames.count == times.count {
                    isDone = true
                    DispatchQueue.main.async { completionHandler(.succeeded(frames)) }
                }

            default:
                isDone = true
                DispatchQueue.main.async { completionHandler(.failed) }
            }
        }
    }
}
