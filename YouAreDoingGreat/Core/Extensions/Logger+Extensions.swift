//
//  Logger+Extensions.swift
//  YouAreDoingGreat
//
//  Created by Claude on 26.01.2026.
//

import OSLog

extension Logger {
    /// General application logger
    static let app = Logger(subsystem: "ee.required.you-are-doing-great", category: "app")

    /// Network operations logger
    static let network = Logger(subsystem: "ee.required.you-are-doing-great", category: "network")

    /// Sync operations logger
    static let sync = Logger(subsystem: "ee.required.you-are-doing-great", category: "sync")

    /// Database operations logger
    static let database = Logger(subsystem: "ee.required.you-are-doing-great", category: "database")
}
