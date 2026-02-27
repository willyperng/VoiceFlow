import Foundation
import AVFoundation

class AudioRecorder: NSObject, ObservableObject {
    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?

    @Published var isRecording = false

    func startRecording() throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("recording.wav")

        audioEngine = AVAudioEngine()
        let inputNode = audioEngine!.inputNode
        let inputFormat = inputNode.outputFormat(forBus: 0)

        vfLog("[AudioRecorder] Native format: \(inputFormat)")

        audioFile = try AVAudioFile(forWriting: url, settings: inputFormat.settings)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            do {
                try self?.audioFile?.write(from: buffer)
            } catch {
                vfLog("[AudioRecorder] Error writing buffer: \(error)")
            }
        }

        try audioEngine!.start()
        isRecording = true
        vfLog("[AudioRecorder] Recording started")
        return url
    }

    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine = nil
        audioFile = nil
        isRecording = false
        vfLog("[AudioRecorder] Recording stopped")
    }
}
