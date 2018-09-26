import UIKit

struct MetadataImage {
    let image: UIImage
    let metadata: CGImageMetadata?
}

extension MetadataImage {

    init(image: CGImage, metadata: CGImageMetadata?) {
        self.init(image: UIImage(cgImage: image), metadata: metadata)
    }

    func jpegData(includingMetadata: Bool = true, compressionQuality: CGFloat = 1) -> Data? {
        let metadata = includingMetadata ? self.metadata : nil
        return image.jpegData(withMetadata: metadata, compressionQuality: compressionQuality)
    }
}
