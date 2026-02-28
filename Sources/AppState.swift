import SwiftUI
import HotKey
import Combine
import AVFoundation

func vfLog(_ message: String) {
    let line = "[\(Date())] \(message)\n"
    print(line, terminator: "")
    if let data = line.data(using: .utf8) {
        let url = URL(fileURLWithPath: "/tmp/voiceflow_debug.log")
        if let fh = try? FileHandle(forWritingTo: url) {
            fh.seekToEndOfFile()
            fh.write(data)
            fh.closeFile()
        } else {
            try? data.write(to: url)
        }
    }
}

class AppState: ObservableObject {
    @Published var isRecording = false
    @Published var statusMessage = "Idle"
    @Published var bypassPermissions = false

    private let recorder = AudioRecorder()
    private let transcriber = TranscriptionService()
    private let injector = TextInjector()
    private var hotKey: HotKey?
    private var hotKeyEnglish: HotKey?
    private var hotKeyBypass: HotKey?
    private var cancellables = Set<AnyCancellable>()

    private var recordingURL: URL?
    private var transcriptionLanguage: String? = "zh"  // default: Traditional Chinese
    
    init() {
        // Request microphone permission
        AVCaptureDevice.requestAccess(for: .audio) { granted in
            vfLog("[AppState] Microphone permission: \(granted ? "granted" : "denied")")
        }

        // Prompt for Accessibility permission if not granted
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        let trusted = AXIsProcessTrustedWithOptions(options)
        vfLog("[AppState] Accessibility trusted: \(trusted)")

        // Initialize Hotkeys
        hotKey = HotKey(key: .v, modifiers: [.command, .option])
        hotKeyEnglish = HotKey(key: .b, modifiers: [.command, .option])
        hotKeyBypass = HotKey(key: .tab, modifiers: [.shift])
        vfLog("[AppState] HotKeys registered: Cmd+Option+V (中文), Cmd+Option+B (English), Shift+Tab (bypass cycle)")
        setupHandlers()

        statusMessage = "Loading model..."
        Task {
            await transcriber.initialize()
            await MainActor.run {
                statusMessage = transcriber.initError ?? "Ready"
                vfLog("[AppState] Model init complete. Status: \(statusMessage)")
            }
        }
    }
    
    private func setupHandlers() {
        hotKey?.keyDownHandler = { [weak self] in
            vfLog("[AppState] Hotkey fired (中文)")
            self?.transcriptionLanguage = "zh"
            self?.toggleRecording()
        }

        hotKeyEnglish?.keyDownHandler = { [weak self] in
            vfLog("[AppState] Hotkey fired (English)")
            self?.transcriptionLanguage = "en"
            self?.toggleRecording()
        }

        hotKeyBypass?.keyDownHandler = { [weak self] in
            guard let self = self else { return }
            self.bypassPermissions.toggle()
            self.injector.bypassPermissions = self.bypassPermissions
            let label = self.bypassPermissions ? "Bypass ON (Clipboard only)" : "Bypass OFF (Auto-paste)"
            self.statusMessage = label
            vfLog("[AppState] \(label)")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self, !self.isRecording else { return }
                self.statusMessage = self.bypassPermissions ? "Ready (Bypass)" : "Ready"
            }
        }

        // Listen to transcriber results
        transcriber.$transcribedText
            .receive(on: RunLoop.main)
            .sink { [weak self] text in
                if !text.isEmpty {
                    self?.injector.inject(text: text)
                    self?.statusMessage = "Injected"
                }
            }
            .store(in: &cancellables)
    }
    
    func toggleRecording() {
        if isRecording {
            stopAndTranscribe()
        } else {
            start()
        }
    }
    
    private func start() {
        do {
            vfLog("[AppState] Starting recording...")
            recordingURL = try recorder.startRecording()
            isRecording = true
            statusMessage = "Recording..."
        } catch {
            vfLog("[AppState] Recording error: \(error)")
            statusMessage = "Error: \(error.localizedDescription)"
        }
    }
    
    private func stopAndTranscribe() {
        recorder.stopRecording()
        isRecording = false
        statusMessage = "Transcribing..."
        
        guard let url = recordingURL else { return }
        transcriber.transcribe(audioURL: url, language: transcriptionLanguage) { [weak self] text in
            if text != nil {
                self?.statusMessage = "Done"
            } else {
                self?.statusMessage = "Transcription Failed"
            }
        }
    }
}
