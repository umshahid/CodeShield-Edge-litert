import Foundation

public final class ScamRiskAnalyzer: Sendable {
    private struct Signal: Sendable {
        let tag: String
        let points: Int
        let pattern: RegexPattern
        let reason: String
    }

    private let signals: [Signal]
    private let codeSharingNegation = RegexPattern(#"(no\s+need\s+to\s+send\s+(the\s+)?(codes?|pins?|numbers?)|do\s+not\s+send\s+(the\s+)?(codes?|pins?|numbers?)|don't\s+send\s+(the\s+)?(codes?|pins?|numbers?))"#)

    public init() {
        self.signals = [
            Signal(tag: "gift_card_payment", points: 18, pattern: RegexPattern(#"\b(gift\s*cards?|apple\s*cards?|itunes|target\s*cards?|steam\s*cards?|google\s*play|amazon\s*cards?|vanilla|prepaid\s*visa|raz(er)?\s*gold|ebay\s*cards?)\b"#), reason: "Asks for gift cards or prepaid cards"),
            Signal(tag: "send_code", points: 35, pattern: RegexPattern(#"\b(send|text|share|upload|read|give|provide|photograph|take\s+a\s+picture|send\s+a\s+photo)\b.{0,80}\b(code|pin|claim\s*code|redemption|numbers?|back\s+of\s+the\s+card|receipt)\b"#), reason: "Asks for the card code, PIN, receipt, or a photo of the back"),
            Signal(tag: "urgency", points: 12, pattern: RegexPattern(#"\b(urgent|immediately|right\s+now|asap|today|within\s+\d+\s+(minutes?|hours?)|before\s+\d|do\s+it\s+now|time\s+sensitive)\b"#), reason: "Uses urgency or a deadline"),
            Signal(tag: "secrecy", points: 18, pattern: RegexPattern(#"\b(do\s+not\s+tell|don't\s+tell|keep\s+this\s+secret|confidential|stay\s+on\s+the\s+phone|do\s+not\s+hang\s+up|don't\s+hang\s+up|no\s+one\s+else\s+can\s+know)\b"#), reason: "Tells the person to keep it secret or stay on the phone"),
            Signal(tag: "government_impersonation", points: 22, pattern: RegexPattern(#"\b(irs|ftc|fbi|police|sheriff|social\s+security|ssa|medicare|court|warrant|tax\s+office|customs|border\s+patrol|government)\b"#), reason: "Claims to be a government, court, police, or benefits office"),
            Signal(tag: "tech_support_impersonation", points: 16, pattern: RegexPattern(#"\b(microsoft|apple\s+support|amazon\s+security|paypal|bank\s+fraud|virus|hacked|refund\s+department|support\s+agent|security\s+team)\b"#), reason: "Looks like tech support, bank, marketplace, or refund impersonation"),
            Signal(tag: "family_emergency", points: 22, pattern: RegexPattern(#"\b(grandma|grandpa|mom|dad|aunt|uncle|grandson|granddaughter|nephew|niece|jail|arrested|hospital|accident|bail|lawyer|public\s+defender)\b"#), reason: "Uses family emergency language"),
            Signal(tag: "threat", points: 14, pattern: RegexPattern(#"\b(arrest|deport|lawsuit|suspended|locked|shut\s*off|fine|penalty|warrant|lose\s+your|freeze\s+your\s+account)\b"#), reason: "Threatens punishment, account loss, or legal trouble"),
            Signal(tag: "remote_control", points: 12, pattern: RegexPattern(#"\b(anydesk|teamviewer|remote\s+access|screen\s+share|install\s+this\s+app|verification\s+app)\b"#), reason: "Mentions remote access or installing a verification app"),
            Signal(tag: "suspicious_link", points: 30, pattern: RegexPattern(#"\b((https?:\/\/|www\.)[^\s]+|[a-z0-9-]+\.(click|top|xyz|icu|buzz|live|site|online|info|zip|mov|ru|cn|tk|ml|ga|cf)\b[^\s]*)"#), reason: "Includes a suspicious, shortened, or unusual link"),
            Signal(tag: "brand_impersonation_link", points: 34, pattern: RegexPattern(#"\b(apple|icloud|amazon|paypal|microsoft|google|irs|ssa|bank|chase|wellsfargo|zelle|venmo)[a-z0-9.-]{0,40}(login|verify|security|support|account|billing|wallet|gift|redeem)[a-z0-9.-]*\.[a-z]{2,}\b|\b(login|verify|security|support|account|billing|wallet|gift|redeem)[a-z0-9.-]{0,40}(apple|icloud|amazon|paypal|microsoft|google|irs|ssa|bank|chase|wellsfargo|zelle|venmo)[a-z0-9.-]*\.[a-z]{2,}\b"#), reason: "Uses a link that appears to impersonate a trusted brand"),
            Signal(tag: "url_shortener", points: 24, pattern: RegexPattern(#"\b(bit\.ly|tinyurl\.com|t\.co|goo\.gl|ow\.ly|is\.gd|cutt\.ly|rebrand\.ly|rb\.gy|shorturl\.at|lnkd\.in)\/[a-z0-9]+"#), reason: "Uses a shortened link that hides the destination"),
            Signal(tag: "credential_request", points: 18, pattern: RegexPattern(#"\b(verify|confirm|unlock|secure|restore|reactivate|validate|claim|login|sign\s*in)\b.{0,80}\b(account|identity|apple\s*id|password|payment|wallet|refund|prize|benefits?)\b"#), reason: "Asks the person to verify or unlock an account"),
        ]
    }

    public func analyze(_ message: String) -> RiskAssessment {
        let text = message
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !text.isEmpty else {
            return RiskAssessment(
                level: .low,
                score: 0,
                category: "No message",
                summary: "No suspicious message was provided.",
                safeNextStep: "Paste or share the message before sending any gift card code.",
                reasons: [],
                tags: []
            )
        }

        var score = 0
        var reasons: [String] = []
        var tags: [String] = []

        for signal in signals where signal.pattern.containsMatch(in: text) {
            if signal.tag == "send_code", negatesCodeSharing(text) {
                continue
            }
            score += signal.points
            reasons.append(signal.reason)
            tags.append(signal.tag)
        }

        let tagSet = Set(tags)
        let giftCard = tagSet.contains("gift_card_payment")
        let sendCode = tagSet.contains("send_code")
        let pressure = tagSet.contains("urgency") || tagSet.contains("secrecy") || tagSet.contains("threat")
        let impersonation = tagSet.contains("government_impersonation") || tagSet.contains("tech_support_impersonation") || tagSet.contains("family_emergency")
        let riskyLink = tagSet.contains("suspicious_link") || tagSet.contains("brand_impersonation_link") || tagSet.contains("url_shortener")
        let credentialRequest = tagSet.contains("credential_request")

        if giftCard && sendCode {
            score += 25
            reasons.append("Combines gift cards with a request for card numbers or photos")
        }
        if giftCard && pressure {
            score += 15
            reasons.append("Combines gift cards with pressure tactics")
        }
        if giftCard && impersonation {
            score += 15
            reasons.append("Combines gift cards with impersonation")
        }
        if sendCode && pressure {
            score += 10
            reasons.append("Pressures the person to transmit an irreversible code")
        }
        if riskyLink && pressure {
            score += 12
            reasons.append("Combines a risky link with urgency or threats")
        }
        if riskyLink && impersonation {
            score += 16
            reasons.append("Combines a risky link with impersonation")
        }
        if riskyLink && credentialRequest {
            score += 20
            reasons.append("Combines a risky link with account verification language")
        }

        let level = levelFor(score)
        let category = categoryFor(tagSet)

        return RiskAssessment(
            level: level,
            score: min(100, score),
            category: category,
            summary: summaryFor(level: level, category: category),
            safeNextStep: safeStepFor(tagSet),
            reasons: reasons,
            tags: tags
        )
    }

    private func negatesCodeSharing(_ text: String) -> Bool {
        codeSharingNegation.containsMatch(in: text)
    }

    private func levelFor(_ score: Int) -> RiskLevel {
        if score >= 70 { return .high }
        if score >= 35 { return .review }
        return .low
    }

    private func categoryFor(_ tags: Set<String>) -> String {
        if tags.contains("family_emergency") { return "Family emergency impersonation" }
        if tags.contains("government_impersonation") { return "Government or law enforcement impersonation" }
        if tags.contains("tech_support_impersonation") { return "Tech support or account impersonation" }
        if tags.contains("brand_impersonation_link") || tags.contains("suspicious_link") || tags.contains("url_shortener") { return "Suspicious link or account verification" }
        if tags.contains("gift_card_payment") { return "Gift card payment request" }
        return "General message"
    }

    private func summaryFor(level: RiskLevel, category: String) -> String {
        switch level {
        case .high:
            return "This strongly matches a known gift card scam pattern: \(category)."
        case .review:
            return "This has warning signs and should be verified before any code is shared."
        case .low:
            return "No major gift card scam pattern was detected."
        }
    }

    private func safeStepFor(_ tags: Set<String>) -> String {
        if tags.contains("family_emergency") {
            return "Call the family member using a saved contact, not a number from this message."
        }
        if tags.contains("government_impersonation") {
            return "Stop replying, then contact the agency using its official website or a known number."
        }
        if tags.contains("tech_support_impersonation") {
            return "Do not install remote access tools. Contact the company through the app or official website."
        }
        if tags.contains("brand_impersonation_link") || tags.contains("suspicious_link") || tags.contains("url_shortener") {
            return "Do not open the link. Go to the official app or website yourself."
        }
        if tags.contains("gift_card_payment") {
            return "Do not send gift card numbers or PINs. Real payments do not require gift card codes."
        }
        return "Verify the sender through a separate trusted channel before sharing codes or receipts."
    }
}
