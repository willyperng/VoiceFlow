import SwiftUI
import HotKey
import AppKit

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
    
    var body: some Scene {
        MenuBarExtra("VoiceFlow", systemImage: "mic.fill") {
            Text("Status: \(appState.statusMessage)")
            Divider()
            Button("Settings") {
                // Show settings
            }
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
            panel.contentView = NSHostingView(rootView: RecordingOverlayView(appState: appState))
            overlayWindow = panel
        }
        
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.midX - 125
            let y = screenRect.minY + 100 // Bottom centerish
            overlayWindow?.setFrameOrigin(NSPoint(x: x, y: y))
        }
        
        overlayWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func hideOverlay() {
        overlayWindow?.orderOut(nil)
    }
}
