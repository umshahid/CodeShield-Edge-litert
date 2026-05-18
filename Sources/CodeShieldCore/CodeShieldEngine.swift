import Foundation

public final class CodeShieldEngine: Sendable {
    private let scamRiskAnalyzer: ScamRiskAnalyzer
    private let giftCardDetector: GiftCardDetector

    public init(
        scamRiskAnalyzer: ScamRiskAnalyzer = ScamRiskAnalyzer(),
        giftCardDetector: GiftCardDetector = GiftCardDetector()
    ) {
        self.scamRiskAnalyzer = scamRiskAnalyzer
        self.giftCardDetector = giftCardDetector
    }

    public func inspect(message: String, giftCardOcrText: String) -> ShieldVerdict {
        let assessment = scamRiskAnalyzer.analyze(message)
        let scan = giftCardDetector.scan(giftCardOcrText)
        let codePresent = scan.hasCodes

        let highRiskWithCode = assessment.level == .high && codePresent
        let suspiciousWithCode = assessment.level == .review && codePresent
        let codeWithoutContext = assessment.level == .low && codePresent
        let blockShare = highRiskWithCode || suspiciousWithCode

        let headline: String
        let body: String

        if highRiskWithCode {
            headline = "Do not send this gift-card code"
            body = "This message strongly matches a gift-card scam and the card code was detected locally. Verify through a trusted contact before sending anything."
        } else if suspiciousWithCode {
            headline = "Pause before sharing this code"
            body = "The message has scam warning signs. Verify through a trusted contact before sending any gift card numbers."
        } else if codeWithoutContext {
            headline = "Gift card code detected"
            body = "A gift card code is visible, but this conversation does not look like a scam. CodeShield will allow it."
        } else if assessment.tags.contains("brand_impersonation_link") || assessment.tags.contains("suspicious_link") || assessment.tags.contains("url_shortener") {
            headline = "Suspicious link detected"
            body = "This message includes a link with scam warning signs. Do not open it from the message; use the official app or website instead."
        } else if assessment.level == .high {
            headline = "High-risk gift card scam pattern"
            body = "No card code was detected yet. Do not buy or send gift cards in response to this message."
        } else if assessment.level == .review {
            headline = "Warning signs found"
            body = "Verify the sender through a separate trusted channel before taking action."
        } else {
            headline = "No major gift-card scam pattern found"
            body = "CodeShield did not find a strong scam pattern, but never send card codes to someone you do not personally trust."
        }

        return ShieldVerdict(
            riskAssessment: assessment,
            giftCardScan: scan,
            blockShare: blockShare,
            headline: headline,
            body: body
        )
    }
}
