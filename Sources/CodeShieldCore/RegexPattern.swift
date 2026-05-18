import Foundation

struct RegexPattern: @unchecked Sendable {
    private let expression: NSRegularExpression

    init(_ pattern: String, options: NSRegularExpression.Options = [.caseInsensitive]) {
        do {
            self.expression = try NSRegularExpression(pattern: pattern, options: options)
        } catch {
            preconditionFailure("Invalid regex pattern: \(pattern)")
        }
    }

    func containsMatch(in text: String) -> Bool {
        firstMatch(in: text) != nil
    }

    func firstMatch(in text: String) -> NSTextCheckingResult? {
        expression.firstMatch(in: text, range: fullRange(in: text))
    }

    func matches(in text: String) -> [NSTextCheckingResult] {
        expression.matches(in: text, range: fullRange(in: text))
    }

    private func fullRange(in text: String) -> NSRange {
        NSRange(text.startIndex..<text.endIndex, in: text)
    }
}
