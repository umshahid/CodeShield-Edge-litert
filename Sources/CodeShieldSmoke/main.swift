import CodeShieldCore
import Foundation

func require(_ condition: @autoclosure () -> Bool, _ message: String) {
    if !condition() {
        fputs("FAIL: \(message)\n", stderr)
        exit(1)
    }
}

let highRisk = CodeShieldEngine().inspect(
    message: """
    Grandma I was arrested after an accident. Do not tell mom.
    Please buy two Apple gift cards today and send a picture of the back with the PIN.
    """,
    giftCardOcrText: """
    Apple Gift Card
    PIN: X4KJ-P92Q-7LMA-882Z
    Keep your receipt
    """
)

require(highRisk.riskAssessment.level == .high, "family emergency scam should be high risk")
require(highRisk.blockShare, "gift card code in high-risk context should block share")
require(highRisk.giftCardScan.codes.count == 1, "should detect exactly one card code")
require(
    highRisk.giftCardScan.redactedText.contains("PIN: [GIFT CARD CODE BLOCKED]"),
    "card code should be redacted"
)

let benign = CodeShieldEngine().inspect(
    message: "Can you pick up a Target gift card for the raffle basket? No need to send codes.",
    giftCardOcrText: ""
)
require(benign.riskAssessment.level == .low, "benign gift card mention should stay low")
require(!benign.blockShare, "benign gift card mention without code should not block")

let reference = GiftCardDetector().scan("Reference number: 1029 8841 7722 9011")
require(!reference.hasCodes, "unlabeled numeric reference should not redact")

let compactApple = CodeShieldEngine().inspect(
    message: """
    Grandma, I was arrested after an accident. Please do not tell mom.
    I need two $100 Apple gift cards grandma, please help.
    """,
    giftCardOcrText: """
    Apple Gift Card
    XTF7LQJ4XL9YWFDV
    Go to apple.com/redeem to add to your Apple Account.
    Do not share your code.
    """
)
require(compactApple.blockShare, "compact Apple redemption code should block")
require(
    compactApple.giftCardScan.redactedText.contains("[GIFT CARD CODE BLOCKED]"),
    "compact Apple redemption code should be redacted"
)

let benignCodeShare = CodeShieldEngine().inspect(
    message: "Here is the Apple gift card for your birthday. Add it whenever you want.",
    giftCardOcrText: """
    Apple Gift Card
    XTF7LQJ4XL9YWFDV
    Go to apple.com/redeem to add to your Apple Account.
    """
)
require(benignCodeShare.riskAssessment.level == .low, "benign code share should stay low risk")
require(!benignCodeShare.blockShare, "benign code share should be allowed")
require(benignCodeShare.giftCardScan.hasCodes, "benign code share should still detect the code")

let suspiciousLink = CodeShieldEngine().inspect(
    message: "Apple Support urgent: verify your Apple ID now at https://appleid-security-login.xyz/account or your account will be locked.",
    giftCardOcrText: ""
)
require(suspiciousLink.riskAssessment.level == .high, "brand impersonation link should be high risk")
require(!suspiciousLink.blockShare, "link warning without a card code should not block sending")
require(suspiciousLink.riskAssessment.tags.contains("brand_impersonation_link"), "should tag brand impersonation link")
require(suspiciousLink.headline == "Suspicious link detected", "should surface suspicious link headline")

let suspiciousLinkWithCode = CodeShieldEngine().inspect(
    message: "Apple Support urgent: verify your account at https://appleid-security-login.xyz/account and read me the PIN.",
    giftCardOcrText: "PIN: X4KJ-P92Q-7LMA-882Z"
)
require(suspiciousLinkWithCode.blockShare, "gift card code in suspicious link context should warn before send")

let benignOfficialLink = CodeShieldEngine().inspect(
    message: "For your birthday card, Apple says you can redeem it at apple.com/redeem whenever you want.",
    giftCardOcrText: "Apple Gift Card\nXTF7LQJ4XL9YWFDV"
)
require(benignOfficialLink.riskAssessment.level == .low, "official benign link should stay low risk")
require(!benignOfficialLink.blockShare, "official benign link with a code should be allowed")

print("CodeShieldSmoke passed")
