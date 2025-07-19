//
//  QRCodeHelper.swift
//  bitaxe
//
//  Created by Brent Parks on 6/2/25.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeHelper {
    static func generateQRCode(from string: String, size: CGFloat = 200) -> Image? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator() // Correct way to get the filter
        
        filter.message = Data(string.utf8)
        // You can set error correction level: "L" (low), "M" (medium), "Q" (quartile), "H" (high)
        // filter.correctionLevel = "H" // Example for high correction

        guard let outputImage = filter.outputImage else {
            print("[QRCodeHelper] Failed to generate CIImage for QR code.")
            return nil
        }

        // Scale the CIImage to the desired output size
        let outputImageSize = outputImage.extent.size
        // Avoid division by zero if outputImageSize width or height is 0
        guard outputImageSize.width > 0, outputImageSize.height > 0 else {
            print("[QRCodeHelper] Generated CIImage has zero dimension.")
            return nil
        }
        
        let scaleX = size / outputImageSize.width
        let scaleY = size / outputImageSize.height
        let transformedImage = outputImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        guard let cgImage = context.createCGImage(transformedImage, from: transformedImage.extent) else {
            print("[QRCodeHelper] Failed to create CGImage from CIImage.")
            return nil
        }
        
        #if os(iOS)
        return Image(uiImage: UIImage(cgImage: cgImage))
        #elseif os(macOS)
        // For macOS, NSImage(cgImage:size:) is appropriate.
        // The size parameter for NSImage(cgImage:size:) is in points.
        return Image(nsImage: NSImage(cgImage: cgImage, size: NSSize(width: size, height: size)))
        #else
        // Fallback for other platforms if your app supports them
        print("[QRCodeHelper] QR Code generation not implemented for this platform.")
        return nil
        #endif
    }
}


//  End of QRCodeHelper.swift
