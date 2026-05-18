import AVFoundation
import Speech

@MainActor
final class SpeechCaptureService {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))

    func requestAccess() async -> Bool {
        let speechAllowed = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status == .authorized)
            }
        }
        let micAllowed = await AVCaptureDevice.requestAccess(for: .audio)
        return speechAllowed && micAllowed
    }

    func start(onTranscript: @escaping @MainActor (String) -> Void) throws {
        stop()

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if #available(macOS 13.0, *) {
            request.requiresOnDeviceRecognition = true
        }

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        recognitionRequest = request
        recognitionTask = recognizer?.recognitionTask(with: request) { result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                Task { @MainActor in
                    onTranscript(text)
                }
            }

            if error != nil || result?.isFinal == true {
                Task { @MainActor in
                    self.stop()
                }
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    func stop() {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
    }
}
