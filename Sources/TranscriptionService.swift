import Foundation
import WhisperKit

class TranscriptionService: ObservableObject {
    private var whisperKit: WhisperKit?
    var initError: String?

    @Published var isProcessing = false
    @Published var transcribedText = ""

    func initialize() async {
        vfLog("[TranscriptionService] Initializing WhisperKit...")
        do {
            let modelPath = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Documents/huggingface/models/argmaxinc/whisperkit-coreml/openai_whisper-base")
                .path
            whisperKit = try await WhisperKit(modelFolder: modelPath, download: false)
            vfLog("[TranscriptionService] WhisperKit ready")
        } catch {
            initError = "Model error: \(error.localizedDescription)"
            vfLog("[TranscriptionService] Init failed: \(error)")
        }
    }

    func transcribe(audioURL: URL, language: String? = nil, completion: @escaping (String?) -> Void) {
        guard let whisperKit = whisperKit else {
            vfLog("[TranscriptionService] whisperKit is nil — not initialized yet")
            completion(nil)
            return
        }

        isProcessing = true
        vfLog("[TranscriptionService] Transcribing \(audioURL.path) language=\(language ?? "auto")...")

        Task {
            do {
                let options = DecodingOptions(language: language)
                let result = try await whisperKit.transcribe(audioPath: audioURL.path, decodeOptions: options)
                let text = result.map { $0.text }.joined(separator: " ")
                vfLog("[TranscriptionService] Result: \(text)")

                DispatchQueue.main.async {
                    self.transcribedText = text
                    self.isProcessing = false
                    completion(text)
                }
            } catch {
                vfLog("[TranscriptionService] Transcription error: \(error)")
                DispatchQueue.main.async {
                    self.isProcessing = false
                    completion(nil)
                }
            }
        }
    }
}
