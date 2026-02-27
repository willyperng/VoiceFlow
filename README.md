# VoiceFlow

A macOS menu bar app that records voice via a global hotkey, transcribes it locally using [WhisperKit](https://github.com/argmaxinc/whisperkit), and injects the result as text into the focused application.

All transcription runs on-device — no network connection required at runtime.

## Hotkeys

| Shortcut | Language |
|---|---|
| `Cmd + Option + V` | Chinese (中文) |
| `Cmd + Option + B` | English |

## How It Works

1. Press the hotkey to start recording
2. Press again to stop — a floating overlay shows recording status
3. Audio is transcribed locally via WhisperKit (base model)
4. Transcribed text is pasted into the currently focused app via clipboard + `Cmd+V`

## Requirements

- macOS 14.0+
- **Microphone** permission — for audio capture
- **Accessibility** permission — for simulating keystrokes to paste text

## Model Setup

VoiceFlow uses the WhisperKit CoreML `openai_whisper-base` model. The model must be pre-downloaded to:

```
~/Documents/huggingface/models/argmaxinc/whisperkit-coreml/openai_whisper-base/
```

You can download it by running WhisperKit's CLI or using the Hugging Face Hub.

## Build & Run

```bash
# Build
swift build

# Run
swift run VoiceFlow

# Release build
swift build -c release
```

## Dependencies

- [WhisperKit](https://github.com/argmaxinc/whisperkit) (v0.10.0+) — on-device speech recognition
- [HotKey](https://github.com/soffes/HotKey) (v0.2.1) — global keyboard shortcut registration
