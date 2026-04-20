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
    private var pausedForSleep = false
    private var sleepObserver: NSObjectProtocol?
    private var wakeObserver: NSObjectProtocol?
    private var activityToken: NSObjectProtocol?

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
        registerSleepWakeObservers()
    }

    private func registerSleepWakeObservers() {
        let nc = NSWorkspace.shared.notificationCenter
        sleepObserver = nc.addObserver(
            forName: NSWorkspace.willSleepNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleWillSleep() }
        }
        wakeObserver = nc.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated { self?.handleDidWake() }
        }
    }

    private func handleWillSleep() {
        guard isRunning else { return }
        AppLogger.shared.log("System sleeping — pausing timer (phase=\(phase), remaining=\(remainingSeconds)s)")
        pausedForSleep = true
        timer?.invalidate()
        timer = nil
        endActivityIfNeeded()
    }

    private func handleDidWake() {
        guard pausedForSleep else { return }
        pausedForSleep = false
        AppLogger.shared.log("System woke — resuming timer (phase=\(phase), remaining=\(remainingSeconds)s)")
        if remainingSeconds <= 0 {
            advancePhase()
        }
        startTimer()
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

        AppLogger.shared.log("Rest ended early by user")
        phase = .work
        remainingSeconds = workMinutes * 60
        refreshStatusTitle()
    }

    func quitApplication() {
        NSApplication.shared.terminate(nil)
    }

    func updateWorkMinutes(_ newValue: Int) {
        let clampedValue = max(1, newValue)
        AppLogger.shared.log("Config changed: workMinutes=\(clampedValue)")
        workMinutes = clampedValue
        UserDefaults.standard.set(clampedValue, forKey: Self.workMinutesKey)

        if phase == .work {
            remainingSeconds = clampedValue * 60
        }

        refreshStatusTitle()
    }

    func updateBreakSeconds(_ newValue: Int) {
        let clampedValue = max(1, newValue)
        AppLogger.shared.log("Config changed: breakSeconds=\(clampedValue)")
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

        AppLogger.shared.log("Timer started — phase=\(phase), remaining=\(remainingSeconds)s, workMinutes=\(workMinutes), breakSeconds=\(breakSeconds)")
        isRunning = true
        startTimer()
        refreshStatusTitle()
    }

    private func pause() {
        AppLogger.shared.log("Timer paused — phase=\(phase), remaining=\(remainingSeconds)s")
        isRunning = false
        timer?.invalidate()
        timer = nil
        endActivityIfNeeded()
        refreshStatusTitle()
    }

    private func startTimer() {
        timer?.invalidate()
        beginActivityIfNeeded()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
    }

    private func beginActivityIfNeeded() {
        guard activityToken == nil else { return }
        activityToken = ProcessInfo.processInfo.beginActivity(
            options: [.userInitiated],
            reason: "TakeABreak timer running"
        )
        AppLogger.shared.log("App Nap prevention activated")
    }

    private func endActivityIfNeeded() {
        guard let token = activityToken else { return }
        ProcessInfo.processInfo.endActivity(token)
        activityToken = nil
        AppLogger.shared.log("App Nap prevention released")
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
            let meetingInProgress = MeetingDetector.isMeetingInProgress()
            AppLogger.shared.log("Work cycle ended — meetingDetected=\(meetingInProgress)")
            if meetingInProgress {
                remainingSeconds = meetingRetrySeconds
                sendMeetingDelayNotification()
                refreshStatusTitle()
                return
            }

            sendBreakNotification()
            AppLogger.shared.log("Phase transition: work → rest (breakSeconds=\(breakSeconds))")
            phase = .rest
            remainingSeconds = breakSeconds
        case .rest:
            AppLogger.shared.log("Phase transition: rest → work (workMinutes=\(workMinutes))")
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
        AppLogger.shared.log("Notification sent: break reminder")
        let content = UNMutableNotificationContent()
        content.title = "Time to take a break"
        content.body = "You've been working for \(workMinutes) minutes. Starting a \(breakSeconds)-second break."
        content.sound = .default
        enqueueNotification(content)
    }

    private func sendMeetingDelayNotification() {
        AppLogger.shared.log("Notification sent: meeting delay")
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
