import AppKit
import CodeShieldCore
import Foundation

@MainActor
final class ConversationStore: ObservableObject {
    @Published var selectedSurface: AppSurface = .messages
    @Published var messages: [ChatItem] = [
        ChatItem(sender: "CodeShield", body: "Messages are private and checked on this Mac before gift-card codes are sent.", direction: .system)
    ]
    @Published var outgoingDraft = ""
    @Published var scammerDraft = "Grandma, I was arrested after an accident. Please do not tell mom."
    @Published var pendingAttachment: PendingAttachment?
    @Published var attachmentStatus = ""
    @Published var safetyIntervention: SafetyIntervention?
    @Published var pendingWarning: SafetyWarning?

    @Published var callActive = false
    @Published var callTranscript: [CallTranscriptLine] = []
    @Published var callerDraft = "This is the sheriff's office. Your grandson was arrested after an accident. Do not tell anyone."
    @Published var voiceDraft = "The PIN is ATF7LQJ4AL9YWFDV."
    @Published var isListening = false
    @Published var micStatus = "Microphone idle"
    @Published var transcriptImportStatus = "No transcript imported"

    @Published var gemmaStatus = "Gemma E4B idle"
    @Published var gemmaOutput = ""
    @Published var gemmaRunning = false
    @Published var aiScammerStatus = "AI scammer idle"
    @Published var aiScammerRunning = false
    @Published var aiCallEnabled = false

    private let engine = CodeShieldEngine()
    private let audioPlayer = CallAudioPlayer()
    private let speechCapture = SpeechCaptureService()

    var messageContext: String {
        messages
            .filter { $0.direction != .system }
            .map { "\($0.sender): \($0.body)" }
            .joined(separator: "\n")
    }

    var callContext: String {
        callTranscript
            .map { "\($0.speaker): \($0.text)" }
            .joined(separator: "\n")
    }

    func sendOutgoingMessage() {
        let text = outgoingDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let attachment = pendingAttachment
        guard !text.isEmpty || attachment != nil else { return }

        let attemptedPayload = [text, attachment?.ocrText ?? ""]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
        let context = messageContextIncluding(attemptedOutgoingText: text)
        let verdict = engine.inspect(message: context, giftCardOcrText: attemptedPayload)

        if verdict.blockShare {
            presentWarning(
                verdict: verdict,
                payload: .message(text: text, attachment: attachment),
                surface: .messages,
                body: "This chat matches a gift-card scam pattern, and CodeShield found a redeemable code in what you are about to send. The code has not left this Mac.",
                attemptedPayload: attemptedPayload
            )
            return
        }

        commitOutgoingMessage(text: text, attachment: attachment)
        clearGemma()
    }

    func removePendingAttachment() {
        pendingAttachment = nil
        attachmentStatus = ""
        safetyIntervention = nil
        pendingWarning = nil
    }

    func receiveScammerMessage() {
        let text = scammerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        messages.append(ChatItem(sender: "Unknown", body: text, direction: .incoming))
        scammerDraft = ""
        safetyIntervention = nil
        pendingWarning = nil
        clearGemma()
        updatePassiveSafetyNotice(surface: .messages, context: messageContext)
    }

    func generateAIMessage() {
        guard !aiScammerRunning else { return }
        aiScammerRunning = true
        aiScammerStatus = "Gemma E4B is writing the next message locally..."
        let context = messageContext.isEmpty ? "No conversation yet." : messageContext

        Task.detached {
            let bridge = LiteRTMacBridge()
            do {
                let line = try bridge.generateScammerLine(context: context, surface: "message")
                await MainActor.run {
                    self.messages.append(ChatItem(sender: "Unknown", body: line, direction: .incoming))
                    self.selectedSurface = .messages
                    self.scammerDraft = ""
                    self.safetyIntervention = nil
                    self.pendingWarning = nil
                    self.aiScammerRunning = false
                    self.aiScammerStatus = "AI scammer sent a message."
                    self.clearGemma()
                    self.updatePassiveSafetyNotice(surface: .messages, context: self.messageContext)
                }
            } catch {
                await MainActor.run {
                    self.aiScammerRunning = false
                    self.aiScammerStatus = "AI scammer failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func attachImage(url: URL, image: NSImage?, ocrText: String) {
        pendingAttachment = PendingAttachment(
            fileName: url.lastPathComponent,
            image: image,
            ocrText: ocrText,
            sourceURL: url
        )
        attachmentStatus = ocrText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Attached. No text found yet." : "Attached. Text read locally."
        safetyIntervention = nil
        pendingWarning = nil
        clearGemma()
    }

    func beginCall() {
        callActive = true
        selectedSurface = .call
        safetyIntervention = nil
        pendingWarning = nil
        clearGemma()
    }

    func endCall() {
        callActive = false
        aiCallEnabled = false
        aiScammerStatus = "AI scammer idle"
        audioPlayer.stop()
    }

    func startAIScamCall() {
        guard !aiScammerRunning else { return }
        aiCallEnabled = true
        callActive = true
        selectedSurface = .call
        safetyIntervention = nil
        pendingWarning = nil
        micStatus = "AI scam caller active"
        if callTranscript.isEmpty {
            aiScammerStatus = "AI scam caller is starting locally..."
        }
        generateAICallerLine(speak: true)
    }

    func stopAIScamCall() {
        aiCallEnabled = false
        aiScammerStatus = "AI scam caller paused"
        audioPlayer.stop()
    }

    func receiveCallerLine(speak: Bool) {
        let text = callerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        callActive = true
        selectedSurface = .call
        callTranscript.append(CallTranscriptLine(speaker: "Caller", text: text, direction: .incoming))
        if speak {
            audioPlayer.speak(text)
        }
        callerDraft = ""
        safetyIntervention = nil
        pendingWarning = nil
        clearGemma()
        updatePassiveSafetyNotice(surface: .call, context: callContext)
    }

    func generateAICallerLine(speak: Bool) {
        guard !aiScammerRunning else { return }
        aiScammerRunning = true
        aiScammerStatus = "Gemma E4B is writing the next caller line locally..."
        let context = callContext.isEmpty ? messageContext : callContext

        Task.detached {
            let bridge = LiteRTMacBridge()
            do {
                let line = try bridge.generateScammerLine(context: context.isEmpty ? "No call transcript yet." : context, surface: "phone call")
                await MainActor.run {
                    self.callActive = true
                    self.selectedSurface = .call
                    self.callTranscript.append(CallTranscriptLine(speaker: "Caller", text: line, direction: .incoming))
                    if speak {
                        self.audioPlayer.speak(line)
                    }
                    self.callerDraft = ""
                    self.safetyIntervention = nil
                    self.pendingWarning = nil
                    self.aiScammerRunning = false
                    self.aiScammerStatus = self.aiCallEnabled ? "AI scam caller is waiting for you." : "AI scammer added a caller line."
                    self.clearGemma()
                    self.updatePassiveSafetyNotice(surface: .call, context: self.callContext)
                }
            } catch {
                await MainActor.run {
                    self.aiScammerRunning = false
                    self.aiCallEnabled = false
                    self.aiScammerStatus = "AI scammer failed: \(error.localizedDescription)"
                }
            }
        }
    }

    func importCallerTranscript(contents: String, fileName: String) {
        let lines = parseTranscript(contents)
        guard !lines.isEmpty else {
            transcriptImportStatus = "No caller lines found in \(fileName)"
            return
        }

        callActive = true
        selectedSurface = .call
        for line in lines {
            callTranscript.append(line)
        }
        transcriptImportStatus = "Imported \(lines.count) transcript line\(lines.count == 1 ? "" : "s") from \(fileName)"
        safetyIntervention = nil
        pendingWarning = nil
        clearGemma()
        updatePassiveSafetyNotice(surface: .call, context: callContext)
    }

    func sendVoiceLine() {
        let text = voiceDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        callActive = true
        selectedSurface = .call

        let verdict = engine.inspect(message: callContext, giftCardOcrText: text)
        if verdict.blockShare {
            presentWarning(
                verdict: verdict,
                payload: .voice(text: text),
                surface: .call,
                body: "The caller is pushing for a redeemable gift-card code, and CodeShield heard one in your response. The audio has not been sent to the caller.",
                attemptedPayload: text
            )
            return
        }

        callTranscript.append(CallTranscriptLine(speaker: "You", text: text, direction: .outgoing))
        voiceDraft = ""
        clearGemma()
        continueAICallIfNeeded()
    }

    func cancelWarningSend() {
        guard let warning = pendingWarning else { return }
        pendingWarning = nil
        safetyIntervention = SafetyIntervention(
            title: "Code was not sent",
            body: warning.surface == .call
                ? "CodeShield kept the spoken gift-card code on this Mac. Hang up and verify the caller through a trusted number."
                : "CodeShield kept the gift-card code on this Mac. Remove the image or cover the code before sending anything.",
            redactedText: warning.redactedText,
            safeNextStep: warning.safeNextStep,
            surface: warning.surface
        )
    }

    func confirmWarningSend() {
        guard let warning = pendingWarning else { return }
        pendingWarning = nil

        switch warning.payload {
        case .message(let text, let attachment):
            commitOutgoingMessage(text: text, attachment: attachment)
        case .voice(let text):
            callActive = true
            selectedSurface = .call
            callTranscript.append(CallTranscriptLine(speaker: "You", text: text, direction: .outgoing))
            voiceDraft = ""
        }

        safetyIntervention = SafetyIntervention(
            title: "Sent after warning",
            body: "You chose to continue after CodeShield warned that this looked like a gift-card scam.",
            redactedText: warning.redactedText,
            safeNextStep: warning.safeNextStep,
            surface: warning.surface
        )
    }

    func toggleListening() {
        if isListening {
            speechCapture.stop()
            isListening = false
            micStatus = voiceDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "No speech captured" : "Speech captured locally"
            return
        }

        Task {
            micStatus = "Requesting microphone access..."
            let allowed = await speechCapture.requestAccess()
            guard allowed else {
                micStatus = "Microphone or speech permission denied"
                return
            }

            do {
                voiceDraft = ""
                isListening = true
                micStatus = "Listening locally..."
                try speechCapture.start { [weak self] transcript in
                    self?.voiceDraft = transcript
                    self?.micStatus = transcript.isEmpty ? "Listening locally..." : "Speech captured locally"
                }
            } catch {
                isListening = false
                micStatus = "Could not start microphone"
            }
        }
    }

    func stopListeningAndSend() {
        if isListening {
            speechCapture.stop()
            isListening = false
            micStatus = "Speech captured locally"
        }
        sendVoiceLine()
    }

    func reset() {
        messages = [
            ChatItem(sender: "CodeShield", body: "Messages are private and checked on this Mac before gift-card codes are sent.", direction: .system)
        ]
        outgoingDraft = ""
        scammerDraft = "Grandma, I was arrested after an accident. Please do not tell mom."
        pendingAttachment = nil
        attachmentStatus = ""
        safetyIntervention = nil
        pendingWarning = nil
        callActive = false
        callTranscript = []
        callerDraft = "This is the sheriff's office. Your grandson was arrested after an accident. Do not tell anyone."
        voiceDraft = "The PIN is ATF7LQJ4AL9YWFDV."
        isListening = false
        micStatus = "Microphone idle"
        transcriptImportStatus = "No transcript imported"
        aiScammerStatus = "AI scammer idle"
        aiScammerRunning = false
        aiCallEnabled = false
        audioPlayer.stop()
        speechCapture.stop()
        clearGemma()
    }

    private func messageContextIncluding(attemptedOutgoingText text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return messageContext }
        return [messageContext, "You: \(trimmed)"]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }

    private func commitOutgoingMessage(text: String, attachment: PendingAttachment?) {
        if !text.isEmpty {
            messages.append(ChatItem(sender: "You", body: text, direction: .outgoing))
        }

        if let attachment {
            messages.append(
                ChatItem(
                    sender: "You",
                    body: attachment.fileName,
                    direction: .outgoing,
                    attachment: attachment
                )
            )
        }

        outgoingDraft = ""
        pendingAttachment = nil
        attachmentStatus = ""
    }

    private func presentWarning(
        verdict: ShieldVerdict,
        payload: WarningPayload,
        surface: AppSurface,
        body: String,
        attemptedPayload: String
    ) {
        safetyIntervention = nil
        pendingWarning = SafetyWarning(
            title: "Do not send this gift-card code",
            body: body,
            redactedText: verdict.giftCardScan.redactedText,
            safeNextStep: verdict.riskAssessment.safeNextStep,
            surface: surface,
            payload: payload
        )
        runGemmaCheck(context: surface == .messages ? messageContext : callContext, attemptedPayload: attemptedPayload)
    }

    private func updatePassiveSafetyNotice(surface: AppSurface, context: String) {
        let verdict = engine.inspect(message: context, giftCardOcrText: "")
        guard verdict.riskAssessment.level != .low else {
            if safetyIntervention?.surface == surface {
                safetyIntervention = nil
            }
            return
        }

        safetyIntervention = SafetyIntervention(
            title: verdict.headline,
            body: verdict.body,
            redactedText: "",
            safeNextStep: verdict.riskAssessment.safeNextStep,
            surface: surface
        )
    }

    private func parseTranscript(_ contents: String) -> [CallTranscriptLine] {
        contents
            .split(whereSeparator: \.isNewline)
            .compactMap { rawLine in
                let parsed = parseTranscriptLine(String(rawLine))
                guard !parsed.text.isEmpty else { return nil }
                return CallTranscriptLine(speaker: parsed.speaker, text: parsed.text, direction: parsed.direction)
            }
    }

    private func parseTranscriptLine(_ rawLine: String) -> (speaker: String, text: String, direction: MessageDirection) {
        let trimmed = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("Caller", "", .incoming)
        }

        let lowered = trimmed.lowercased()
        let prefixes: [(String, String, MessageDirection)] = [
            ("caller:", "Caller", .incoming),
            ("scammer:", "Caller", .incoming),
            ("unknown:", "Caller", .incoming),
            ("agent:", "Caller", .incoming),
            ("you:", "You", .outgoing),
            ("victim:", "You", .outgoing),
            ("grandma:", "You", .outgoing),
        ]

        for (prefix, speaker, direction) in prefixes where lowered.hasPrefix(prefix) {
            let text = String(trimmed.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            return (speaker, text, direction)
        }

        return ("Caller", trimmed, .incoming)
    }

    private func continueAICallIfNeeded() {
        guard aiCallEnabled else { return }
        aiScammerStatus = "AI scam caller is thinking locally..."

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            guard self.aiCallEnabled, !self.aiScammerRunning, self.pendingWarning == nil else { return }
            self.generateAICallerLine(speak: true)
        }
    }

    private func runGemmaCheck(context: String, attemptedPayload: String) {
        gemmaRunning = true
        gemmaStatus = "Gemma E4B is reviewing the warning locally..."
        gemmaOutput = ""

        Task.detached {
            let bridge = LiteRTMacBridge()
            do {
                let output = try bridge.analyzeRiskJSON(context: context, attemptedPayload: attemptedPayload)
                await MainActor.run {
                    self.gemmaRunning = false
                    self.gemmaStatus = "Gemma E4B reviewed the risky send."
                    self.gemmaOutput = output
                }
            } catch {
                await MainActor.run {
                    self.gemmaRunning = false
                    self.gemmaStatus = "Gemma E4B failed; local warning stayed active."
                    self.gemmaOutput = error.localizedDescription
                }
            }
        }
    }

    private func clearGemma() {
        gemmaRunning = false
        gemmaStatus = "Gemma E4B idle"
        gemmaOutput = ""
    }
}

enum AppSurface: String, CaseIterable, Identifiable {
    case messages = "Messages"
    case call = "Call"

    var id: String { rawValue }
}

enum MessageDirection {
    case incoming
    case outgoing
    case system
}

struct PendingAttachment: Identifiable {
    let id = UUID()
    let fileName: String
    let image: NSImage?
    let ocrText: String
    let sourceURL: URL
}

struct ChatItem: Identifiable {
    let id = UUID()
    let sender: String
    let body: String
    let direction: MessageDirection
    let attachment: PendingAttachment?
    let timestamp = Date()

    init(sender: String, body: String, direction: MessageDirection, attachment: PendingAttachment? = nil) {
        self.sender = sender
        self.body = body
        self.direction = direction
        self.attachment = attachment
    }
}

struct CallTranscriptLine: Identifiable {
    let id = UUID()
    let speaker: String
    let text: String
    let direction: MessageDirection
}

struct SafetyIntervention: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let redactedText: String
    let safeNextStep: String
    let surface: AppSurface
}

enum WarningPayload {
    case message(text: String, attachment: PendingAttachment?)
    case voice(text: String)
}

struct SafetyWarning: Identifiable {
    let id = UUID()
    let title: String
    let body: String
    let redactedText: String
    let safeNextStep: String
    let surface: AppSurface
    let payload: WarningPayload

    var attachment: PendingAttachment? {
        if case .message(_, let attachment) = payload {
            return attachment
        }
        return nil
    }

    var attemptedText: String {
        switch payload {
        case .message(let text, _):
            return text
        case .voice(let text):
            return text
        }
    }
}
