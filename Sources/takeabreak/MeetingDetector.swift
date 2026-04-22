import Foundation

struct MeetingDetector {
    private static let standaloneMeetingKeywords = [
        "lark meetings",
        "lark meeting",
        "larkmeeting",
        "feishu meeting",
        "feishu meetings",
        "feishumeeting",
        "meeting.app/contents/macos",
        "/meeting",
        "video_conference_sdk",
        "mediatransmit",
    ]

    static func isMeetingInProgress() -> Bool {
        guard let processList = runningProcessCommands() else {
            return false
        }

        return processList.contains { command in
            let normalizedCommand = command.lowercased()
            let isLarkMeetingSDK =
                normalizedCommand.contains("larksuite.app") &&
                normalizedCommand.contains("video_conference_sdk")

            if isLarkMeetingSDK {
                return true
            }

            return standaloneMeetingKeywords.contains { keyword in
                normalizedCommand.contains(keyword)
            }
        }
    }

    private static func runningProcessCommands() -> [String]? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/ps")
        process.arguments = ["-ax", "-o", "comm="]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
        } catch {
            return nil
        }

        // Drain stdout before waiting: readDataToEndOfFile returns when the
        // child closes its pipe (at exit). Calling waitUntilExit first
        // deadlocks once ps output exceeds the pipe buffer (~16KB).
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            return nil
        }

        let output = String(decoding: data, as: UTF8.self)
        return output
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }
}
