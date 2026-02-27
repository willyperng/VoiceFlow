import SwiftUI
import HotKey
import AppKit
import ServiceManagement

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.prohibited)
    }
}

@main
struct VoiceFlowApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @State private var overlayWindow: NSPanel?
    @State private var launchAtLogin = (SMAppService.mainApp.status == .enabled)

    var body: some Scene {
        MenuBarExtra("VoiceFlow", systemImage: "mic.fill") {
            Text("Status: \(appState.statusMessage)")
            Divider()
            Toggle("Launch at Login", isOn: Binding(
                get: { launchAtLogin },
                set: { newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                        launchAtLogin = newValue
                    } catch {
                        vfLog("[VoiceFlowApp] Launch at login error: \(error)")
                    }
                }
            ))
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        .onChange(of: appState.isRecording) { _, recording in
            if recording {
                showOverlay()
            } else {
                // Delay hiding slightly to show transcription status
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    hideOverlay()
                }
            }
        }
    }
    
    private func showOverlay() {
        if overlayWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 250, height: 80),
                styleMask: [.nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isFloatingPanel = true
            panel.level = .floating
            panel.backgroundColor = .clear
            panel.isOpaque = false
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: RecordingOverlayView(appState: appState))
            overlayWindow = panel
        }

        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 125
            let y = screenRect.minY + 100 // Bottom centerish
            overlayWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        }

        overlayWindow?.orderFrontRegardless()
    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }
}
