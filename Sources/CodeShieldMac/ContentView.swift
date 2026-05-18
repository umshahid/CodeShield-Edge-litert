import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var store: ConversationStore

    var body: some View {
        HStack(spacing: 0) {
            sidebar
                .frame(width: 248)
            Divider()
            mainSurface
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(item: $store.pendingWarning) { warning in
            SafetyWarningSheet(warning: warning)
                .environmentObject(store)
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text("CodeShield")
                    .font(.title.weight(.bold))
                HStack(spacing: 6) {
                    statusPill("Gemma E4B")
                    statusPill("Local")
                }
            }
            .padding(18)

            VStack(spacing: 6) {
                sidebarRow(.messages, title: "Unknown Number", subtitle: lastMessagePreview, systemImage: "person.crop.circle.badge.questionmark")
                sidebarRow(.call, title: "Audio Call", subtitle: store.callActive ? "In call" : "Ready", systemImage: "phone.fill")
            }
            .padding(.horizontal, 10)

            Spacer()

            VStack(spacing: 10) {
                Button {
                    openWindow(id: "scammer-console")
                } label: {
                    Label("Open Scammer Console", systemImage: "rectangle.connected.to.line.below")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    store.reset()
                } label: {
                    Label("Reset Conversation", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.borderless)
            .padding(16)
        }
        .background(Color(nsColor: .underPageBackgroundColor))
    }

    private var lastMessagePreview: String {
        store.messages.last(where: { $0.direction != .system })?.body ?? "Private chat"
    }

    private func sidebarRow(_ surface: AppSurface, title: String, subtitle: String, systemImage: String) -> some View {
        Button {
            store.selectedSurface = surface
        } label: {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(.teal)
                    .frame(width: 32)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                        .lineLimit(1)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(10)
            .background(store.selectedSurface == surface ? Color.teal.opacity(0.16) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
    }

    private var mainSurface: some View {
        Group {
            switch store.selectedSurface {
            case .messages:
                MessagesSurface()
            case .call:
                CallSurface()
            }
        }
    }

    private func statusPill(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.caption.weight(.bold))
            .foregroundStyle(.teal)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.teal.opacity(0.14))
            .clipShape(Capsule())
    }
}

private struct MessagesSurface: View {
    @EnvironmentObject private var store: ConversationStore

    var body: some View {
        VStack(spacing: 0) {
            conversationHeader
            Divider()
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(store.messages) { item in
                            MessageBubble(item: item)
                                .id(item.id)
                        }

                        if let pending = store.pendingAttachment {
                            PendingAttachmentView(attachment: pending, status: store.attachmentStatus) {
                                store.removePendingAttachment()
                            }
                        }

                        if let intervention = store.safetyIntervention, intervention.surface == .messages {
                            SafetyInterventionView(intervention: intervention)
                        }
                    }
                    .padding(22)
                }
                .onChange(of: store.messages.count) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: store.pendingAttachment?.id) { _, _ in
                    scrollToBottom(proxy)
                }
                .onChange(of: store.safetyIntervention?.id) { _, _ in
                    scrollToBottom(proxy)
                }
            }
            Divider()
            messageComposer
        }
    }

    private var conversationHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.questionmark")
                .font(.system(size: 34))
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text("Unknown Number")
                    .font(.headline)
                Text("Not in contacts")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "lock.fill")
                .foregroundStyle(.secondary)
            Text("Protected locally")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var messageComposer: some View {
        VStack(spacing: 10) {
            if store.gemmaRunning || !store.gemmaOutput.isEmpty {
                GemmaStatusStrip()
            }

            HStack(alignment: .bottom, spacing: 10) {
                Button {
                    pickImage()
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.teal)

                TextField("Message", text: $store.outgoingDraft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit {
                        store.sendOutgoingMessage()
                    }

                Button {
                    store.sendOutgoingMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.teal)
            }
        }
        .padding(16)
    }

    private func pickImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.image, .pdf]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        store.attachmentStatus = "Reading text locally..."
        Task {
            do {
                let text = try await MacOCRService.recognizeText(from: url)
                let image = NSImage(contentsOf: url)
                await MainActor.run {
                    store.attachImage(url: url, image: image, ocrText: text)
                }
            } catch {
                let image = NSImage(contentsOf: url)
                await MainActor.run {
                    store.attachImage(url: url, image: image, ocrText: "")
                    store.attachmentStatus = "Attached. OCR could not read text."
                }
            }
        }
    }

    private func scrollToBottom(_ proxy: ScrollViewProxy) {
        if let id = store.messages.last?.id {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo(id, anchor: .bottom)
            }
        }
    }
}

private struct MessageBubble: View {
    let item: ChatItem

    var body: some View {
        HStack {
            if item.direction == .outgoing { Spacer(minLength: 100) }

            VStack(alignment: item.direction == .outgoing ? .trailing : .leading, spacing: 6) {
                if item.direction != .system {
                    Text(item.sender)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    if let attachment = item.attachment {
                        AttachmentThumbnail(attachment: attachment)
                    }
                    Text(item.body)
                }
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(background)
                .foregroundStyle(item.direction == .outgoing ? Color.white : Color.primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            if item.direction != .outgoing { Spacer(minLength: 100) }
        }
    }

    private var background: Color {
        switch item.direction {
        case .incoming:
            return Color(nsColor: .controlBackgroundColor)
        case .outgoing:
            return .teal
        case .system:
            return Color.orange.opacity(0.13)
        }
    }
}

private struct PendingAttachmentView: View {
    let attachment: PendingAttachment
    let status: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Spacer(minLength: 100)
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Label(attachment.fileName, systemImage: "photo")
                        .font(.headline)
                    Spacer()
                    Text(status)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(action: onRemove) {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.secondary)
                    .help("Remove attachment")
                }
                AttachmentThumbnail(attachment: attachment)
            }
            .padding(12)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.teal.opacity(0.35)))
        }
    }
}

private struct AttachmentThumbnail: View {
    let attachment: PendingAttachment

    var body: some View {
        Group {
            if let image = attachment.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 280, maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Label(attachment.fileName, systemImage: "doc")
                    .frame(maxWidth: 280, alignment: .leading)
            }
        }
    }
}

private struct CallSurface: View {
    @EnvironmentObject private var store: ConversationStore

    var body: some View {
        VStack(spacing: 0) {
            callHeader
            Divider()
            ScrollView {
                VStack(spacing: 14) {
                    ForEach(store.callTranscript) { line in
                        CallLineView(line: line)
                    }

                    if store.callTranscript.isEmpty {
                        VStack(spacing: 14) {
                            Image(systemName: "phone.circle.fill")
                                .font(.system(size: 58))
                                .foregroundStyle(.teal)
                            Text("Incoming caller")
                                .font(.title2.weight(.semibold))
                            Text("Answer when ready. CodeShield checks spoken gift-card codes locally before they are transmitted.")
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 360)
                    }

                    if let intervention = store.safetyIntervention, intervention.surface == .call {
                        SafetyInterventionView(intervention: intervention)
                    }
                }
                .padding(22)
            }
            Divider()
            voiceComposer
        }
    }

    private var callHeader: some View {
        HStack(spacing: 12) {
            Image(systemName: "phone.circle.fill")
                .font(.system(size: 34))
                .foregroundStyle(.teal)
            VStack(alignment: .leading, spacing: 2) {
                Text("Unknown Caller")
                    .font(.headline)
                Text(store.callActive ? "Call active" : "Waiting")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button {
                if store.aiCallEnabled {
                    store.stopAIScamCall()
                } else {
                    store.startAIScamCall()
                }
            } label: {
                Label(store.aiCallEnabled ? "Pause AI Caller" : "Start AI Scam Call", systemImage: "sparkles")
            }
            Button {
                store.beginCall()
            } label: {
                Label("Answer", systemImage: "phone.fill")
            }
            Button {
                store.endCall()
            } label: {
                Label("End", systemImage: "phone.down.fill")
            }
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 14)
    }

    private var voiceComposer: some View {
        VStack(spacing: 10) {
            if store.gemmaRunning || !store.gemmaOutput.isEmpty {
                GemmaStatusStrip()
            }

            HStack(spacing: 10) {
                Button {
                    store.toggleListening()
                } label: {
                    Image(systemName: store.isListening ? "stop.circle.fill" : "waveform.circle.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(store.isListening ? Color.orange : Color.teal)

                TextField("Speak to caller", text: $store.voiceDraft, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...4)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(Color(nsColor: .controlBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .onSubmit {
                        store.stopListeningAndSend()
                    }
                Button {
                    store.stopListeningAndSend()
                } label: {
                    Image(systemName: "mic.fill")
                        .font(.title3)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.teal)
            }

            Text(store.micStatus)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            if store.aiCallEnabled || store.aiScammerRunning {
                HStack(spacing: 8) {
                    Image(systemName: store.aiScammerRunning ? "hourglass" : "brain.head.profile")
                        .foregroundStyle(store.aiScammerRunning ? Color.orange : Color.teal)
                    Text(store.aiScammerStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding(16)
    }
}

private struct CallLineView: View {
    let line: CallTranscriptLine

    var body: some View {
        HStack {
            if line.direction == .outgoing { Spacer(minLength: 100) }
            VStack(alignment: line.direction == .outgoing ? .trailing : .leading, spacing: 5) {
                Text(line.speaker)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Text(line.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(background)
                    .foregroundStyle(line.direction == .outgoing ? Color.white : Color.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            if line.direction != .outgoing { Spacer(minLength: 100) }
        }
    }

    private var background: Color {
        switch line.direction {
        case .incoming:
            return Color(nsColor: .controlBackgroundColor)
        case .outgoing:
            return .teal
        case .system:
            return Color.orange.opacity(0.14)
        }
    }
}

private struct SafetyInterventionView: View {
    let intervention: SafetyIntervention

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: intervention.surface == .call ? "mic.slash.fill" : "lock.shield.fill")
                    .font(.title2)
                    .foregroundStyle(.orange)
                VStack(alignment: .leading, spacing: 5) {
                    Text(intervention.title)
                        .font(.headline)
                    Text(intervention.body)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            if !intervention.redactedText.isEmpty {
                Text(intervention.redactedText)
                    .font(.system(.body, design: .monospaced))
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(nsColor: .textBackgroundColor))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            Text(intervention.safeNextStep)
                .font(.callout.weight(.semibold))
        }
        .padding(16)
        .background(Color.orange.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.45)))
    }
}

private struct SafetyWarningSheet: View {
    @EnvironmentObject private var store: ConversationStore
    let warning: SafetyWarning
    @State private var overrideArmed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.16))
                        .frame(width: 72, height: 72)
                    Image(systemName: warning.surface == .call ? "mic.badge.xmark" : "exclamationmark.triangle.fill")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(.red)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Do Not Send This Code")
                        .font(.largeTitle.weight(.bold))
                    Text("The gift-card code has not left this Mac.")
                        .font(.headline)
                        .foregroundStyle(.red)
                    Text(warning.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 8) {
                Label("Checked locally", systemImage: "lock.fill")
                Label(warning.surface == .call ? "Audio held" : "Message held", systemImage: warning.surface == .call ? "waveform.badge.exclamationmark" : "paperplane.circle")
                Label("Gemma E4B", systemImage: "brain.head.profile")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)

            if let attachment = warning.attachment {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Attached image")
                        .font(.headline)
                    AttachmentThumbnail(attachment: attachment)
                }
            }

            if !warning.attemptedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(warning.surface == .call ? "Your spoken response" : "Your message")
                        .font(.headline)
                    Text(warning.attemptedText)
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(nsColor: .textBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            if !warning.redactedText.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("CodeShield redacted the code")
                        .font(.headline)
                    Text(warning.redactedText)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.35)))
                }
            }

            Text(warning.safeNextStep)
                .font(.callout.weight(.semibold))
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if store.gemmaRunning || !store.gemmaOutput.isEmpty {
                GemmaStatusStrip()
            }

            HStack {
                Button(role: .cancel) {
                    store.cancelWarningSend()
                } label: {
                    Label("Don't Send", systemImage: "hand.raised.fill")
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                if overrideArmed {
                    Button(role: .destructive) {
                        store.confirmWarningSend()
                    } label: {
                        Label("Send Anyway", systemImage: warning.surface == .call ? "mic.fill" : "paperplane.fill")
                    }
                } else {
                    Button {
                        overrideArmed = true
                    } label: {
                        Label("I Understand", systemImage: "exclamationmark.triangle.fill")
                    }
                }
            }
            .font(.headline)
        }
        .padding(28)
        .frame(width: 680)
    }
}

private struct GemmaStatusStrip: View {
    @EnvironmentObject private var store: ConversationStore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: store.gemmaRunning ? "hourglass" : "brain.head.profile")
                    .foregroundStyle(store.gemmaRunning ? Color.orange : Color.teal)
                Text(store.gemmaStatus)
                    .font(.caption.weight(.semibold))
                Spacer()
            }

            if !store.gemmaOutput.isEmpty {
                Text(store.gemmaOutput)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding(10)
        .background(Color(nsColor: .controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ScammerConsoleView: View {
    @EnvironmentObject private var store: ConversationStore

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Scammer Console")
                    .font(.title2.weight(.bold))
                Text("Backstage controls for the person pretending to be the scammer.")
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 10) {
                Text("Message Victim")
                    .font(.headline)
                TextField("Incoming message", text: $store.scammerDraft, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button {
                        store.generateAIMessage()
                    } label: {
                        Label("AI Next Message", systemImage: "sparkles")
                    }
                    .disabled(store.aiScammerRunning)

                    Button {
                        store.receiveScammerMessage()
                    } label: {
                        Label("Send Draft", systemImage: "bubble.left.fill")
                    }
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 10) {
                Text("Speak on Call")
                    .font(.headline)
                TextField("Caller line", text: $store.callerDraft, axis: .vertical)
                    .lineLimit(3...8)
                    .textFieldStyle(.roundedBorder)
                HStack {
                    Button {
                        store.generateAICallerLine(speak: true)
                    } label: {
                        Label("AI Speak", systemImage: "sparkles")
                    }
                    .disabled(store.aiScammerRunning)

                    Button {
                        store.receiveCallerLine(speak: true)
                    } label: {
                        Label("Speak Aloud", systemImage: "speaker.wave.2.fill")
                    }
                    Button {
                        store.receiveCallerLine(speak: false)
                    } label: {
                        Label("Add Transcript", systemImage: "text.bubble.fill")
                    }
                    Button {
                        importTranscript()
                    } label: {
                        Label("Import Transcript", systemImage: "doc.text.fill")
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: store.aiScammerRunning ? "hourglass" : "brain.head.profile")
                        .foregroundStyle(store.aiScammerRunning ? Color.orange : Color.teal)
                    Text(store.aiScammerStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 8) {
                    Image(systemName: "doc.text")
                        .foregroundStyle(.secondary)
                    Text(store.transcriptImportStatus)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(22)
        .frame(width: 560, height: 490)
    }

    private func importTranscript() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.plainText, .text]

        guard panel.runModal() == .OK, let url = panel.url else {
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let text = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .utf16)
                ?? String(data: data, encoding: .isoLatin1)
                ?? ""
            store.importCallerTranscript(contents: text, fileName: url.lastPathComponent)
        } catch {
            store.transcriptImportStatus = "Could not import \(url.lastPathComponent)"
        }
    }
}
