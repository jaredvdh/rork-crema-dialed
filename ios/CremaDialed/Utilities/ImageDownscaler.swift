//
//  ImageDownscaler.swift
//  CremaDialed
//
//  Shared helper that resizes and recompresses photos before they are persisted
//  as Data. Keeping stored images to a sane size avoids bloating the SwiftData
//  store with full-resolution library or camera images.
//

import UIKit

enum ImageDownscaler {
    /// Longest-edge cap (in points) for stored images.
    static let defaultMaxDimension: CGFloat = 1600
    /// JPEG compression quality used when re-encoding.
    static let defaultQuality: CGFloat = 0.8

    /// Downscale + recompress raw image data. Returns the original data
    /// unchanged if it cannot be decoded as an image.
    static func downscaledJPEG(
        from data: Data,
        maxDimension: CGFloat = defaultMaxDimension,
        quality: CGFloat = defaultQuality
    ) -> Data {
        guard let image = UIImage(data: data) else { return data }
        return downscaledJPEG(from: image, maxDimension: maxDimension, quality: quality) ?? data
    }

    /// Downscale + recompress a UIImage to JPEG data.
    static func downscaledJPEG(
        from image: UIImage,
        maxDimension: CGFloat = defaultMaxDimension,
        quality: CGFloat = defaultQuality
    ) -> Data? {
        resized(image, maxDimension: maxDimension).jpegData(compressionQuality: quality)
    }

    /// Returns the image scaled down so its longest edge is at most
    /// `maxDimension`. Images already within bounds are returned unchanged.
    private static func resized(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longestEdge = max(image.size.width, image.size.height)
        guard longestEdge > maxDimension, longestEdge > 0 else { return image }

        let scale = maxDimension / longestEdge
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)

        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        format.opaque = false
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
