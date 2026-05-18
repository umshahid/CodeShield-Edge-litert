import AppKit
import CoreGraphics
import Foundation
import UniformTypeIdentifiers
import Vision

enum MacOCRError: LocalizedError {
    case unsupportedFile
    case unreadableImage
    case noCGImage

    var errorDescription: String? {
        switch self {
        case .unsupportedFile:
            return "Unsupported file type"
        case .unreadableImage:
            return "Could not read image"
        case .noCGImage:
            return "Could not create image bitmap"
        }
    }
}

enum MacOCRService {
    static func recognizeText(from url: URL) async throws -> String {
        let values = try url.resourceValues(forKeys: [.contentTypeKey])
        guard let contentType = values.contentType else {
            throw MacOCRError.unsupportedFile
        }

        if contentType.conforms(to: .pdf) {
            return try await recognizePDF(url)
        }
        if contentType.conforms(to: .image) {
            return try await recognizeImage(url)
        }
        throw MacOCRError.unsupportedFile
    }

    private static func recognizeImage(_ url: URL) async throws -> String {
        guard let image = NSImage(contentsOf: url) else {
            throw MacOCRError.unreadableImage
        }
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw MacOCRError.noCGImage
        }
        return try await recognize(cgImage)
    }

    private static func recognizePDF(_ url: URL) async throws -> String {
        guard let document = CGPDFDocument(url as CFURL), let page = document.page(at: 1) else {
            throw MacOCRError.unreadableImage
        }

        let rect = page.getBoxRect(.mediaBox)
        let scale: CGFloat = 2
        let width = Int(rect.width * scale)
        let height = Int(rect.height * scale)
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            throw MacOCRError.unreadableImage
        }

        context.setFillColor(NSColor.white.cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        context.scaleBy(x: scale, y: scale)
        context.drawPDFPage(page)

        guard let cgImage = context.makeImage() else {
            throw MacOCRError.noCGImage
        }
        return try await recognize(cgImage)
    }

    private static func recognize(_ cgImage: CGImage) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let lines = (request.results as? [VNRecognizedTextObservation] ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                continuation.resume(returning: lines.joined(separator: "\n"))
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            do {
                try VNImageRequestHandler(cgImage: cgImage).perform([request])
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
