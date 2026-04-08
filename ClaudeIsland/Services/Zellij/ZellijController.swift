//
//  ZellijController.swift
//  ClaudeIsland
//
//  Sends keystrokes to zellij panes via the zellij CLI
//

import Foundation
import os.log

/// Sends messages to zellij sessions via the zellij CLI
actor ZellijController {
    static let shared = ZellijController()

    nonisolated static let logger = Logger(subsystem: "com.claudeisland", category: "Zellij")

    private var cachedPath: String?

    private init() {}

    // MARK: - Path Discovery

    func getZellijPath() -> String? {
        if let cached = cachedPath { return cached }

        let possiblePaths = [
            "/opt/homebrew/bin/zellij",  // Apple Silicon Homebrew
            "/usr/local/bin/zellij",     // Intel Homebrew
            "/usr/bin/zellij",
        ]

        for path in possiblePaths {
            if FileManager.default.isExecutableFile(atPath: path) {
                cachedPath = path
                return path
            }
        }

        return nil
    }

    func isZellijAvailable() -> Bool {
        getZellijPath() != nil
    }

    // MARK: - Message Sending

    /// Send a message to a zellij session.
    /// Targets the focused pane of the given session (or the active session if sessionName is nil).
    func sendMessage(_ message: String, sessionName: String?) async -> Bool {
        guard let zellijPath = getZellijPath() else {
            Self.logger.error("zellij binary not found")
            return false
        }

        var baseArgs: [String] = []
        if let name = sessionName {
            baseArgs = ["--session", name]
        }

        do {
            // Send the message text
            let textArgs = baseArgs + ["action", "write-chars", message]
            Self.logger.debug("Sending text to zellij session: \(sessionName ?? "active", privacy: .public)")
            _ = try await ProcessExecutor.shared.run(zellijPath, arguments: textArgs)

            // Send Enter to submit
            let enterArgs = baseArgs + ["action", "write-chars", "\n"]
            _ = try await ProcessExecutor.shared.run(zellijPath, arguments: enterArgs)

            return true
        } catch {
            Self.logger.error("Failed to send to zellij: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
