import SwiftUI

struct ContentView: View {
    @StateObject private var recorder = RecorderViewModel()

    var body: some View {
        VStack(spacing: 10) {
            Text(recorder.statusTitle)
                .font(.headline)
                .multilineTextAlignment(.center)

            Text(recorder.elapsedText)
                .font(.system(.title2, design: .monospaced))
                .contentTransition(.numericText())

            Button {
                Task {
                    await recorder.toggleRecording()
                }
            } label: {
                Image(systemName: recorder.isRecording ? "stop.fill" : "mic.fill")
                    .font(.title2)
                    .frame(width: 48, height: 48)
            }
            .buttonStyle(.borderedProminent)
            .tint(recorder.isRecording ? .red : .green)

            if let message = recorder.message {
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .minimumScaleFactor(0.7)
            }
        }
        .padding()
        .task {
            await recorder.prepare()
        }
    }
}

