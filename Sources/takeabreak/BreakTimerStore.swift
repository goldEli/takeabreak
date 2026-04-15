import AppKit
import Combine
import Foundation
import SwiftUI
import UserNotifications

@MainActor
final class BreakTimerStore: ObservableObject {
    enum Phase {
        case work
        case rest
    }

    @Published private(set) var workMinutes: Int
    @Published private(set) var breakSeconds: Int

    @Published private(set) var isRunning: Bool = false
    @Published private(set) var phase: Phase = .work
    @Published private(set) var remainingSeconds: Int
    @Published private(set) var statusTitle: String = "TakeABreak"

    private var timer: Timer?
    private let meetingRetrySeconds = 60

    private static let workMinutesKey = "workMinutes"
    private static let breakSecondsKey = "breakSeconds"

    init() {
        let defaults = UserDefaults.standard
        let storedWorkMinutes = defaults.object(forKey: Self.workMinutesKey) as? Int ?? 30
        let storedBreakSeconds = defaults.object(forKey: Self.breakSecondsKey) as? Int ?? 10

        workMinutes = max(1, storedWorkMinutes)
        breakSeconds = max(1, storedBreakSeconds)
        remainingSeconds = max(1, storedWorkMinutes) * 60
        refreshStatusTitle()
    }

    var primaryButtonTitle: String {
        isRunning ? "Pause" : "Start"
    }

    var phaseText: String {
        switch phase {
        case .work:
            return "Working"
        case .rest:
            return "On Break"
        }
    }

    var countdownText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var workMinutesBinding: Binding<Int> {
        Binding(
            get: { self.workMinutes },
            set: { self.updateWorkMinutes($0) }
        )
    }

    var breakSecondsBinding: Binding<Int> {
        Binding(
            get: { self.breakSeconds },
            set: { self.updateBreakSeconds($0) }
        )
    }

    func toggleRunning() {
        isRunning ? pause() : start()
    }

    func endRestEarly() {
        guard phase == .rest else {
            return
        }

        phase = .work
        remainingSeconds = workMinutes * 60
        refreshStatusTitle()
    }

    func quitApplication() {
        NSApplication.shared.terminate(nil)
    }

    func updateWorkMinutes(_ newValue: Int) {
        let clampedValue = max(1, newValue)
        workMinutes = clampedValue
        UserDefaults.standard.set(clampedValue, forKey: Self.workMinutesKey)

        if phase == .work {
            remainingSeconds = clampedValue * 60
        }

        refreshStatusTitle()
    }

    func updateBreakSeconds(_ newValue: Int) {
        let clampedValue = max(1, newValue)
        breakSeconds = clampedValue
        UserDefaults.standard.set(clampedValue, forKey: Self.breakSecondsKey)

        if phase == .rest {
            remainingSeconds = clampedValue
        }

        refreshStatusTitle()
    }

    private func start() {
        if phase == .work, remainingSeconds <= 0 {
            remainingSeconds = workMinutes * 60
        } else if phase == .rest, remainingSeconds <= 0 {
            remainingSeconds = breakSeconds
        }

        isRunning = true
        startTimer()
        refreshStatusTitle()
    }

    private func pause() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        refreshStatusTitle()
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func tick() {
        guard isRunning else {
            return
        }

        remainingSeconds -= 1

        if remainingSeconds <= 0 {
            advancePhase()
        } else {
            refreshStatusTitle()
        }
    }

    private func advancePhase() {
        switch phase {
        case .work:
            if MeetingDetector.isMeetingInProgress() {
                remainingSeconds = meetingRetrySeconds
                sendMeetingDelayNotification()
                refreshStatusTitle()
                return
            }

            sendBreakNotification()
            phase = .rest
            remainingSeconds = breakSeconds
        case .rest:
            phase = .work
            remainingSeconds = workMinutes * 60
        }

        refreshStatusTitle()
    }

    private func refreshStatusTitle() {
        guard isRunning else {
            statusTitle = ""
            return
        }

        let prefix = switch phase {
        case .work: "W"
        case .rest: "B"
        }

        statusTitle = "\(prefix) \(countdownText)"
    }

    private func sendBreakNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Time to take a break"
        content.body = "You've been working for \(workMinutes) minutes. Starting a \(breakSeconds)-second break."
        content.sound = .default
        enqueueNotification(content)
    }

    private func sendMeetingDelayNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Meeting detected"
        content.body = "Break postponed. The app will check again in 60 seconds."
        content.sound = .default
        enqueueNotification(content)
    }

    private func enqueueNotification(_ content: UNMutableNotificationContent) {
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
