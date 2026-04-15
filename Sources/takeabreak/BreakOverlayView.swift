import SwiftUI

struct BreakOverlayView: View {
    @ObservedObject var store: BreakTimerStore

    var body: some View {
        ZStack {
            Color.black
                .ignoresSafeArea()

            VStack(spacing: 24) {
                Text("Take a Break")
                    .font(.system(size: 44, weight: .bold))

                Text(store.countdownText)
                    .font(.system(size: 92, weight: .bold, design: .monospaced))

                Button("End Break") {
                    store.endRestEarly()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
            .foregroundStyle(.white)
        }
    }
}
