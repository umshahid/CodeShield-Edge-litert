import XCTest
@testable import CodeShieldCore

final class CodeShieldCoreTests: XCTestCase {
    func testFamilyEmergencyGiftCardCodeBlocks() {
        let verdict = CodeShieldEngine().inspect(
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

        XCTAssertEqual(verdict.riskAssessment.level, .high)
        XCTAssertTrue(verdict.blockShare)
        XCTAssertEqual(verdict.giftCardScan.codes.count, 1)
        XCTAssertTrue(verdict.giftCardScan.redactedText.contains("PIN: [GIFT CARD CODE BLOCKED]"))
        XCTAssertTrue(verdict.giftCardScan.redactedText.contains("Keep your receipt"))
    }

    func testBenignGiftCardMentionDoesNotBlockWithoutCode() {
        let verdict = CodeShieldEngine().inspect(
            message: "Can you pick up a Target gift card for the raffle basket? No need to send codes.",
            giftCardOcrText: ""
        )

        XCTAssertEqual(verdict.riskAssessment.level, .low)
        XCTAssertFalse(verdict.blockShare)
    }

    func testUnlabeledGroupedNumberDoesNotRedact() {
        let scan = GiftCardDetector().scan("Reference number: 1029 8841 7722 9011")
        XCTAssertFalse(scan.hasCodes)
    }

    func testUnlabeledAppleCompactRedemptionCodeBlocks() {
        let verdict = CodeShieldEngine().inspect(
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

        XCTAssertTrue(verdict.blockShare)
        XCTAssertEqual(verdict.giftCardScan.codes.first?.normalized, "XTF7LQJ4XL9YWFDV")
        XCTAssertTrue(verdict.giftCardScan.redactedText.contains("[GIFT CARD CODE BLOCKED]"))
    }

    func testBenignConversationWithVisibleCodeAllowsShare() {
        let verdict = CodeShieldEngine().inspect(
            message: "Here is the Apple gift card for your birthday. Add it whenever you want.",
            giftCardOcrText: """
            Apple Gift Card
            XTF7LQJ4XL9YWFDV
            Go to apple.com/redeem to add to your Apple Account.
            """
        )

        XCTAssertEqual(verdict.riskAssessment.level, .low)
        XCTAssertFalse(verdict.blockShare)
        XCTAssertEqual(verdict.giftCardScan.codes.first?.normalized, "XTF7LQJ4XL9YWFDV")
    }

    func testSuspiciousBrandLinkWarnsWithoutBlockingUntilCodeIsShared() {
        let verdict = CodeShieldEngine().inspect(
            message: "Apple Support urgent: verify your Apple ID now at https://appleid-security-login.xyz/account or your account will be locked.",
            giftCardOcrText: ""
        )

        XCTAssertEqual(verdict.riskAssessment.level, .high)
        XCTAssertFalse(verdict.blockShare)
        XCTAssertTrue(verdict.riskAssessment.tags.contains("brand_impersonation_link"))
        XCTAssertEqual(verdict.headline, "Suspicious link detected")
    }

    func testSuspiciousLinkContextWithGiftCardCodeWarnsBeforeSend() {
        let verdict = CodeShieldEngine().inspect(
            message: "Apple Support urgent: verify your account at https://appleid-security-login.xyz/account and read me the PIN.",
            giftCardOcrText: "PIN: X4KJ-P92Q-7LMA-882Z"
        )

        XCTAssertTrue(verdict.blockShare)
    }

    func testOfficialBenignLinkWithVisibleCodeAllowsShare() {
        let verdict = CodeShieldEngine().inspect(
            message: "For your birthday card, Apple says you can redeem it at apple.com/redeem whenever you want.",
            giftCardOcrText: """
            Apple Gift Card
            XTF7LQJ4XL9YWFDV
            """
        )

        XCTAssertEqual(verdict.riskAssessment.level, .low)
        XCTAssertFalse(verdict.blockShare)
    }
}
