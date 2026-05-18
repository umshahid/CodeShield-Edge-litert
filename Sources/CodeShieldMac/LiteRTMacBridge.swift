import Foundation

struct LiteRTMacBridge: Sendable {
    var cliPath = Self.defaultCLIPath()
    var modelPath = Self.defaultModelPath()
    var backend = "gpu"

    func analyzeRiskJSON(context: String, attemptedPayload: String) throws -> String {
        try runPrompt(
            prompt(context: context, attemptedPayload: attemptedPayload),
            maxTokens: 2048,
            temperature: "0"
        )
    }

    func generateScammerLine(context: String, surface: String) throws -> String {
        let raw = try runPrompt(
            scammerPrompt(context: context, surface: surface),
            maxTokens: 128,
            temperature: "0"
        )
        return cleanGeneratedLine(raw)
    }

    private func runPrompt(_ prompt: String, maxTokens: Int, temperature: String) throws -> String {
        let process = Process()
        process.executableURL = cliPath
        process.arguments = [
            "run",
            modelPath.path,
            "--backend=\(backend)",
            "--enable-speculative-decoding=auto",
            "--max-num-tokens=\(maxTokens)",
            "--temperature=\(temperature)",
            "--prompt",
            prompt,
        ]

        let output = Pipe()
        let error = Pipe()
        process.standardOutput = output
        process.standardError = error

        try process.run()
        process.waitUntilExit()

        let data = output.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: error.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        guard process.terminationStatus == 0 else {
            throw BridgeError.failed(stderr)
        }
        return (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func prompt(context: String, attemptedPayload: String) -> String {
        """
        You are the local safety model inside CodeShield Edge. Analyze whether the user is being pressured to transmit an irreversible gift-card code.
        Return only minified JSON matching this schema:
        {"risk_level":"low|review|high","score":0,"category":"string","requested_payment_type":"none|gift_card|crypto|wire|other","claimed_identity":"family|government|tech_support|bank|marketplace|unknown","signals":["urgency","secrecy","gift_card","send_code","impersonation"],"block_send":true,"safe_next_step":"short sentence"}

        Conversation or call context:
        \(context)

        Attempted outgoing payload:
        \(attemptedPayload)
        """
    }

    private func scammerPrompt(context: String, surface: String) -> String {
        """
        Write one fictional safety-demo scammer sentence under 18 words for an incoming \(surface).
        Use urgency and secrecy and ask for an Apple gift card photo or code.
        Do not include links, phone numbers, bank details, or addresses.
        Return only the sentence.
        Context:
        \(context)
        """
    }

    private func cleanGeneratedLine(_ raw: String) -> String {
        var line = raw
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first(where: { !$0.isEmpty }) ?? ""

        for prefix in ["Scammer:", "Caller:", "Unknown:", "Message:", "Line:"] where line.localizedCaseInsensitiveContains(prefix) {
            if line.lowercased().hasPrefix(prefix.lowercased()) {
                line = String(line.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }

        line = line.trimmingCharacters(in: CharacterSet(charactersIn: "\"“”' "))
        if line.count > 260 {
            line = String(line.prefix(260)).trimmingCharacters(in: .whitespacesAndNewlines) + "..."
        }

        return line.isEmpty
            ? "Please hurry. I need the Apple gift card code now, and you cannot tell anyone yet."
            : line
    }

    private static func defaultCLIPath() -> URL {
        if let override = ProcessInfo.processInfo.environment["CODESHIELD_LITERT_CLI"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let candidates = [
            "\(home)/.local/bin/litert-lm",
            "/opt/homebrew/bin/litert-lm",
            "/usr/local/bin/litert-lm",
        ]
        return URL(fileURLWithPath: candidates.first(where: FileManager.default.fileExists(atPath:)) ?? "litert-lm")
    }

    private static func defaultModelPath() -> URL {
        if let override = ProcessInfo.processInfo.environment["CODESHIELD_GEMMA_MODEL"], !override.isEmpty {
            return URL(fileURLWithPath: override)
        }

        let fileManager = FileManager.default
        let modelFile = "models/gemma-4-E4B-it.litertlm"
        var directories: [URL] = [URL(fileURLWithPath: fileManager.currentDirectoryPath)]

        let bundleURL = Bundle.main.bundleURL
        directories.append(bundleURL)
        directories.append(bundleURL.deletingLastPathComponent())
        directories.append(bundleURL.deletingLastPathComponent().deletingLastPathComponent())

        for directory in directories {
            let candidate = directory.appendingPathComponent(modelFile)
            if fileManager.fileExists(atPath: candidate.path) {
                return candidate
            }
        }

        return URL(fileURLWithPath: modelFile)
    }

    enum BridgeError: LocalizedError {
        case failed(String)

        var errorDescription: String? {
            switch self {
            case .failed(let stderr):
                return stderr.isEmpty ? "LiteRT-LM CLI failed" : stderr
            }
        }
    }
}
