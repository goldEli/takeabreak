import SwiftUI

struct MenuBarContentView: View {
    @ObservedObject var store: BreakTimerStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("TakeABreak")
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Work Minutes")
                    Spacer()
                    TextField("30", value: store.workMinutesBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }

                HStack {
                    Text("Break Seconds")
                    Spacer()
                    TextField("10", value: store.breakSecondsBinding, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 90)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(store.phaseText)
                    .font(.headline)
                Text(store.countdownText)
                    .font(.system(size: 28, weight: .bold, design: .monospaced))
            }

            HStack(spacing: 12) {
                Button(store.primaryButtonTitle) {
                    store.toggleRunning()
                }
                .keyboardShortcut(.defaultAction)

                Button("Quit") {
                    store.quitApplication()
                }
            }

            Button("Show Log in Finder") {
                AppLogger.shared.revealInFinder()
            }
            .buttonStyle(.plain)
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 320)
    }
}
