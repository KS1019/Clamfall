//
//  Logger.swift
//  App
//
//  Created by Kotaro Suto on 2025/02/15.
//

import Foundation
import OSLog

enum Category: String {
    case system, app
}

extension Logger {
    init(_ category: Category) {
        self = .init(subsystem: Bundle.main.bundleIdentifier ?? ProcessInfo.processInfo.globallyUniqueString,
                     category: category.rawValue)
    }
}
