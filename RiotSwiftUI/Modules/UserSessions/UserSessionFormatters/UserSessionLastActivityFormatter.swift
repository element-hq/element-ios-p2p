//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Enables to build last activity date string
class UserSessionLastActivityFormatter {
    
    // MARK: - Constants
    
    private static var lastActivityDateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        dateFormatter.doesRelativeDateFormatting = true
        return dateFormatter
    }()
    
    // MARK: - Public
    
    /// Session last activity string
    func lastActivityDateString(from lastActivityTimestamp: TimeInterval) -> String {
        
        let date = Date(timeIntervalSince1970: lastActivityTimestamp)
        
        return UserSessionLastActivityFormatter.lastActivityDateFormatter.string(from: date)
    }
}
