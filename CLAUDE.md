# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build & Run

```bash
# Build
swift build

# Run
swift run VoiceFlow

# Release build
swift build -c release
```

No test targets or linting tools are configured.

## Architecture

VoiceFlow is a macOS menu bar app (macOS 14.0+) that records voice via a global hotkey, transcribes it locally using Whisper, and injects the result as text into the focused application.

**Data flow:**
```
Cmd+Option+V hotkey → AppState.toggleRecording()
  → AudioRecorder (AVAudioEngine, 16kHz mono WAV)
  → TranscriptionService (WhisperKit, local ggml-base.bin model)
  → TextInjector (copies to clipboard, simulates Cmd+V via CGEvent)
```

**Key files in `Sources/`:**
- `AppState.swift` — Central `ObservableObject`; owns and coordinates all components; manages the global hotkey (HotKey package)
- `AudioRecorder.swift` — Captures mic via `AVAudioEngine`, converts to 16-bit PCM mono 16kHz, writes to a temp `recording.wav`
- `TranscriptionService.swift` — Wraps WhisperKit; loads the model asynchronously on startup from `ggml-base.bin` in the project root
- `TextInjector.swift` — Pastes text by writing to the clipboard then posting `CGEvent` keystrokes for Cmd+V; requires Accessibility permission
- `FloatingOverlay.swift` — Floating semi-transparent overlay window shown during recording/transcription
- `VoiceFlowApp.swift` — SwiftUI `App` entry point with `MenuBarExtra`

**Dependencies (Package.swift):**
- `WhisperKit` (v0.10.0+) — on-device speech recognition
- `HotKey` (v0.2.1) — global keyboard shortcut registration

## macOS Permissions Required

- **Microphone** — for audio capture
- **Accessibility** — for `TextInjector` to simulate keystrokes globally

## Model

`ggml-base.bin` (148 MB) lives in the project root and is loaded directly by `TranscriptionService`. No network access is needed at runtime.
