import Foundation

public enum RiskLevel: String, Sendable {
    case low = "LOW"
    case review = "REVIEW"
    case high = "HIGH"
}

public struct RiskAssessment: Sendable {
    public let level: RiskLevel
    public let score: Int
    public let category: String
    public let summary: String
    public let safeNextStep: String
    public let reasons: [String]
    public let tags: [String]
}

public struct GiftCardCode: Sendable, Identifiable, Hashable {
    public var id: String { normalized }
    public let rawText: String
    public let normalized: String
    public let startOffset: Int
    public let endOffset: Int
    public let nearbyBrand: String
    public let confidence: Int
}

public struct GiftCardScan: Sendable {
    public let codes: [GiftCardCode]
    public let redactedText: String
    public let brands: [String]

    public var hasCodes: Bool {
        !codes.isEmpty
    }
}

public struct ShieldVerdict: Sendable {
    public let riskAssessment: RiskAssessment
    public let giftCardScan: GiftCardScan
    public let blockShare: Bool
    public let headline: String
    public let body: String
}
