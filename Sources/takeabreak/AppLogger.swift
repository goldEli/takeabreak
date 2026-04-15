import AppKit
import Foundation

@MainActor
final class AppLogger {
    static let shared = AppLogger()

    private let fileURL: URL
    private var fileHandle: FileHandle?
    private let formatter: ISO8601DateFormatter
    private let maxFileSize = 2 * 1024 * 1024 // 2 MB

    private init() {
        formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let logsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Logs/TakeABreak", isDirectory: true)
        fileURL = logsDir.appendingPathComponent("takeabreak.log")

        try? FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)
        rotateIfNeeded()

        if !FileManager.default.fileExists(atPath: fileURL.path) {
            FileManager.default.createFile(atPath: fileURL.path, contents: nil)
        }

        fileHandle = try? FileHandle(forWritingTo: fileURL)
        fileHandle?.seekToEndOfFile()
    }

    func log(_ message: String, level: String = "INFO") {
        let timestamp = formatter.string(from: Date())
        let line = "[\(timestamp)] [\(level)] \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        fileHandle?.write(data)
    }

    func revealInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([fileURL])
    }

    private func rotateIfNeeded() {
        guard
            let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
            let size = attrs[.size] as? Int,
            size > maxFileSize
        else { return }

        let backupURL = fileURL.deletingLastPathComponent()
            .appendingPathComponent("takeabreak.1.log")
        try? FileManager.default.removeItem(at: backupURL)
        try? FileManager.default.moveItem(at: fileURL, to: backupURL)
    }
}
