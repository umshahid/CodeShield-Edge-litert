import Foundation

public final class GiftCardDetector: Sendable {
    private let labeledCode = RegexPattern(#"\b(pin|claim\s*code|redemption\s*code|gift\s*card\s*(?:number|code)|card\s*number|access\s*number|security\s*code)\b\s*[:#-]?\s*((?:[A-Z0-9]{4}[- ]){2,6}[A-Z0-9]{3,6}|[A-Z0-9]{10,30})\b"#)
    private let groupedCode = RegexPattern(#"\b(?:[A-Z0-9]{4}[- ]){2,6}[A-Z0-9]{3,6}\b"#)
    private let compactCode = RegexPattern(#"\b[A-Z0-9]{12,24}\b"#)
    private let brandPatterns: [(String, RegexPattern)] = [
        ("Apple", RegexPattern(#"\b(apple|itunes)\b"#)),
        ("Target", RegexPattern(#"\b(target)\b"#)),
        ("Steam", RegexPattern(#"\b(steam)\b"#)),
        ("Google Play", RegexPattern(#"\b(google\s*play)\b"#)),
        ("Amazon", RegexPattern(#"\b(amazon)\b"#)),
        ("Visa Gift", RegexPattern(#"\b(vanilla|visa\s*gift|prepaid\s*visa)\b"#)),
        ("Ebay", RegexPattern(#"\b(ebay)\b"#)),
        ("Walmart", RegexPattern(#"\b(walmart)\b"#)),
        ("Razer Gold", RegexPattern(#"\b(razer\s*gold)\b"#)),
    ]

    public init() {}

    public func scan(_ ocrText: String) -> GiftCardScan {
        var codes: [GiftCardCode] = []
        collectLabeledMatches(in: ocrText, output: &codes)
        collectGroupedMatches(in: ocrText, output: &codes)
        collectCompactMatches(in: ocrText, output: &codes)

        let deduped = dedupe(codes)
        return GiftCardScan(
            codes: deduped,
            redactedText: redact(ocrText, codes: deduped),
            brands: detectBrands(in: ocrText)
        )
    }

    private func collectLabeledMatches(in text: String, output: inout [GiftCardCode]) {
        for match in labeledCode.matches(in: text) {
            let codeRange = match.range(at: 2)
            guard codeRange.location != NSNotFound, let range = Range(codeRange, in: text) else {
                continue
            }
            collect(raw: String(text[range]), range: range, in: text, output: &output)
        }
    }

    private func collectGroupedMatches(in text: String, output: inout [GiftCardCode]) {
        for match in groupedCode.matches(in: text) {
            guard let range = Range(match.range, in: text) else {
                continue
            }
            collect(raw: String(text[range]), range: range, in: text, output: &output)
        }
    }

    private func collectCompactMatches(in text: String, output: inout [GiftCardCode]) {
        for match in compactCode.matches(in: text) {
            guard let range = Range(match.range, in: text) else {
                continue
            }
            collect(raw: String(text[range]), range: range, in: text, output: &output)
        }
    }

    private func collect(raw: String, range: Range<String.Index>, in text: String, output: inout [GiftCardCode]) {
        guard looksLikeGiftCode(raw) else { return }
        let startOffset = text.distance(from: text.startIndex, to: range.lowerBound)
        let endOffset = text.distance(from: text.startIndex, to: range.upperBound)
        let nearby = nearbyText(in: text, startOffset: startOffset, endOffset: endOffset)
        let brand = firstBrand(in: nearby)
        let confidence = confidence(raw: raw, nearby: nearby, brand: brand)
        guard confidence >= 45 else { return }
        output.append(
            GiftCardCode(
                rawText: raw,
                normalized: normalize(raw),
                startOffset: startOffset,
                endOffset: endOffset,
                nearbyBrand: brand,
                confidence: confidence
            )
        )
    }

    private func looksLikeGiftCode(_ raw: String) -> Bool {
        let normalized = normalize(raw)
        guard (10...30).contains(normalized.count) else { return false }
        guard normalized.contains(where: { $0.isNumber }) else { return false }
        guard normalized.range(of: #"GIFTCARD|CLAIMCODE|REDEMPTIONCODE|CARDNUMBER|ACCESSNUMBER|SECURITYCODE"#, options: .regularExpression) == nil else {
            return false
        }
        return normalized.allSatisfy { $0.isLetter || $0.isNumber }
    }

    private func confidence(raw: String, nearby: String, brand: String) -> Int {
        var score = 20
        let lower = nearby.lowercased()
        let hasCodeLabel = lower.range(of: #"(pin|claim code|redemption|gift card|card number|scratch|back of card|access number)"#, options: .regularExpression) != nil
        let numericOnly = normalize(raw).allSatisfy(\.isNumber)

        if !brand.isEmpty { score += 25 }
        if hasCodeLabel { score += 35 }
        if raw.contains("-") || raw.contains(" ") { score += 8 }
        if normalize(raw).count >= 14 { score += 7 }
        if !numericOnly, normalize(raw).contains(where: \.isLetter) { score += 15 }
        if numericOnly, brand.isEmpty, !hasCodeLabel { score -= 35 }
        return min(100, score)
    }

    private func dedupe(_ codes: [GiftCardCode]) -> [GiftCardCode] {
        var seen = Set<String>()
        return codes
            .filter { seen.insert($0.normalized).inserted }
            .sorted { $0.startOffset < $1.startOffset }
    }

    private func redact(_ text: String, codes: [GiftCardCode]) -> String {
        guard !codes.isEmpty else { return text }

        var output = ""
        var cursor = text.startIndex

        for code in codes.sorted(by: { $0.startOffset < $1.startOffset }) {
            guard
                let start = text.index(text.startIndex, offsetBy: code.startOffset, limitedBy: text.endIndex),
                let end = text.index(text.startIndex, offsetBy: code.endOffset, limitedBy: text.endIndex),
                start >= cursor,
                start <= end
            else {
                continue
            }
            output += text[cursor..<start]
            output += "[GIFT CARD CODE BLOCKED]"
            cursor = end
        }
        output += text[cursor..<text.endIndex]
        return output
    }

    private func nearbyText(in text: String, startOffset: Int, endOffset: Int) -> String {
        let lowerOffset = max(0, startOffset - 120)
        let upperOffset = min(text.count, endOffset + 120)
        let lower = text.index(text.startIndex, offsetBy: lowerOffset)
        let upper = text.index(text.startIndex, offsetBy: upperOffset)
        return String(text[lower..<upper])
    }

    private func detectBrands(in text: String) -> [String] {
        var brands: [String] = []
        for (brand, pattern) in brandPatterns where pattern.containsMatch(in: text) {
            brands.append(brand)
        }
        return brands
    }

    private func firstBrand(in text: String) -> String {
        detectBrands(in: text).first ?? ""
    }

    private func normalize(_ raw: String) -> String {
        raw.uppercased().filter { $0.isLetter || $0.isNumber }
    }
}
