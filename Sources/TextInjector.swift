import Foundation
import AppKit

class TextInjector {
    func inject(text: String) {
        // 1. Copy text to clipboard
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // 2. Simulate Command + V
        // Note: This requires Accessibility permissions to work globally.
        let source = CGEventSource(stateID: .combinedSessionState)
        
        let vKeyDown = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true) // 'v' is 0x09
        vKeyDown?.flags = .maskCommand
        
        let vKeyUp = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
        vKeyUp?.flags = .maskCommand
        
        vKeyDown?.post(tap: .cghidEventTap)
        vKeyUp?.post(tap: .cghidEventTap)
    }
}
