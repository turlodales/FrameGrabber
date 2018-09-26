import UIKit

extension CGSize {
    /// The receiver scaled with the screen's scale.
    var scaledToScreen: CGSize {
        let scale = UIScreen.main.scale
        return CGSize(width: width * scale, height: height * scale)
    }
}

extension CGSize {
    /// The receiver's aspect ratio scaled such that it minimally fills the given size.
    func aspectFilling(_ size: CGSize) -> CGSize {
        guard self != .zero else { return .zero }

        let widthScale = size.width / width;
        let heightScale = size.height / height;

        if heightScale > widthScale {
            return CGSize(width: ceil(heightScale * width), height: size.height)
        } else if widthScale > heightScale {
            return CGSize(width: size.width, height: ceil(widthScale * height))
        }

        return size
    }
}
