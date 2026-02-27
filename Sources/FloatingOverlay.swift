import SwiftUI

struct RecordingOverlayView: View {
    @ObservedObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "mic.fill")
                .foregroundColor(.white)
                .font(.system(size: 24))
                .symbolEffect(.pulse, isActive: appState.isRecording)
            
            VStack(alignment: .leading) {
                Text(appState.isRecording ? "Recording..." : appState.statusMessage)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if appState.isRecording {
                    Text("Speak now")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .shadow(radius: 10)
    }
}
