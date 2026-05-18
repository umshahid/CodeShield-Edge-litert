import AppKit
import CodeShieldCore
import Vision

guard CommandLine.arguments.count > 1 else {
    fputs("Usage: CodeShieldOCRDebug /path/to/image\n", stderr)
    exit(2)
}

let url = URL(fileURLWithPath: CommandLine.arguments[1])
guard let image = NSImage(contentsOf: url),
      let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
    fputs("Could not read image\n", stderr)
    exit(1)
}

let request = VNRecognizeTextRequest()
request.recognitionLevel = .accurate
request.usesLanguageCorrection = false

try VNImageRequestHandler(cgImage: cgImage).perform([request])

let text = (request.results ?? [])
    .compactMap { $0.topCandidates(1).first?.string }
    .joined(separator: "\n")

let verdict = CodeShieldEngine().inspect(
    message: """
    Grandma, I was arrested after an accident. Please do not tell mom.
    I need two $100 Apple gift cards grandma, please help.
    """,
    giftCardOcrText: text
)

print("OCR:")
print(text)
print("\nCodes:")
for code in verdict.giftCardScan.codes {
    print("\(code.rawText) -> \(code.normalized), confidence \(code.confidence)")
}
print("\nBlocked: \(verdict.blockShare)")
