import AVKit
import Photos

class Video {
    let asset: PHAsset
    let avAsset: AVAsset

    init(asset: PHAsset, avAsset: AVAsset) {
        self.asset = asset
        self.avAsset = avAsset
    }
}

extension Video {

    /// From PHAsset.
    var metadata: CGImageMetadata {
        return CGImageMetadata.for(creationDate: asset.creationDate, location: asset.location).metadata
    }

    /// From AVAsset falling back to PHAsset.
    var pixelSize: CGSize {
        if let videoSize = videoTrack?.naturalSize, videoSize != .zero {
            return videoSize
        }

        return CGSize(width: asset.pixelWidth, height: asset.pixelHeight)
    }

    var frameRate: Float? {
        return videoTrack?.nominalFrameRate
    }

    var videoTrack: AVAssetTrack? {
        return avAsset.tracks(withMediaType: .video).first
    }
}
