import AppKit
import Combine
import SwiftUI

@MainActor
final class BreakOverlayController {
    private let store: BreakTimerStore
    private var cancellables = Set<AnyCancellable>()
    private var windows: [NSWindow] = []
    private var previousPresentationOptions: NSApplication.PresentationOptions = []

    init(store: BreakTimerStore) {
        self.store = store

        store.$phase
            .combineLatest(store.$isRunning)
            .sink { [weak self] phase, isRunning in
                self?.updateOverlay(phase: phase, isRunning: isRunning)
            }
            .store(in: &cancellables)
    }

    private func updateOverlay(phase: BreakTimerStore.Phase, isRunning: Bool) {
        let shouldShowOverlay = isRunning && phase == .rest

        if shouldShowOverlay {
            showOverlay()
        } else {
            hideOverlay()
        }
    }

    private func showOverlay() {
        guard windows.isEmpty else {
            windows.forEach { $0.orderFrontRegardless() }
            NSApplication.shared.presentationOptions = [.hideDock, .hideMenuBar]
            NSApplication.shared.activate(ignoringOtherApps: true)
            return
        }

        previousPresentationOptions = NSApplication.shared.presentationOptions
        NSApplication.shared.presentationOptions = [.hideDock, .hideMenuBar]

        let createdWindows = NSScreen.screens.map { screen in
            let window = NSWindow(
                contentRect: screen.frame,
                styleMask: .borderless,
                backing: .buffered,
                defer: false,
                screen: screen
            )

            window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .fullScreenDisallowsTiling, .stationary]
            window.level = .screenSaver
            window.backgroundColor = .black
            window.isOpaque = true
            window.hasShadow = false
            window.ignoresMouseEvents = false
            window.isReleasedWhenClosed = false
            window.contentViewController = NSHostingController(rootView: BreakOverlayView(store: store))
            window.setFrame(screen.frame, display: true)
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            return window
        }

        windows = createdWindows
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func hideOverlay() {
        windows.forEach { window in
            window.orderOut(nil)
            window.close()
        }
        windows.removeAll()
        NSApplication.shared.presentationOptions = previousPresentationOptions
    }
}
