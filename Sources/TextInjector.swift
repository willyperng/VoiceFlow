import Foundation
import AppKit

class TextInjector {
    var bypassPermissions = false

    func inject(text: String) {
        vfLog("[TextInjector] Injecting text: \(text)")

        // 1. Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        vfLog("[TextInjector] Clipboard set")

        // Bypass mode: clipboard only, no auto-paste
        if bypassPermissions {
            vfLog("[TextInjector] Bypass mode ON — skipping auto-paste")
            return
        }

        // 2. Check Accessibility permission
        let trusted = AXIsProcessTrusted()
        vfLog("[TextInjector] Accessibility trusted: \(trusted)")

        // 3. Delay then simulate Cmd+V via AppleScript (more reliable than CGEvent)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            let script = NSAppleScript(source: """
                tell application "System Events"
                    keystroke "v" using command down
                end tell
            """)
            var error: NSDictionary?
            script?.executeAndReturnError(&error)
            if let error = error {
                vfLog("[TextInjector] AppleScript error: \(error)")
                // Fallback to CGEvent
                self.pasteViaCGEvent()
            } else {
                vfLog("[TextInjector] Paste via AppleScript succeeded")
            }
        }
    }

    private func pasteViaCGEvent() {
        vfLog("[TextInjector] Falling back to CGEvent paste")
        let source = CGEventSource(stateID: .combinedSessionState)

        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
        vKeyDown?.flags = .maskCommand

        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vKeyUp?.flags = .maskCommand

        vKeyDown?.post(tap: .cghidEventTap)
        vKeyUp?.post(tap: .cghidEventTap)
    }
}
