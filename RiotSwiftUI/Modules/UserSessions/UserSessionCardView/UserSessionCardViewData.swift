// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// View data for UserSessionCardView
struct UserSessionCardViewData {
    
    // MARK: - Constants
    
    private static let userSessionNameFormatter = UserSessionNameFormatter()
    private static let lastActivityDateFormatter = UserSessionLastActivityFormatter()
        
    // MARK: - Properties
    
    var id: String {
        return sessionId
    }
    
    let sessionId: String

    let sessionName: String
    
    let isVerified: Bool
    
    let lastActivityDateString: String?
    
    let lastSeenIPInfo: String?
    
    let deviceAvatarViewData: DeviceAvatarViewData
    
    /// Indicate if the current user session is shown and to adpat the layout
    let isCurrentSessionDisplayMode: Bool
    
    // MARK: - Setup
    
    init(sessionId: String,
         sessionDisplayName: String?,
         deviceType: DeviceType,
         isVerified: Bool,
         lastActivityTimestamp: TimeInterval?,
         lastSeenIP: String?,
         isCurrentSessionDisplayMode: Bool = false) {
        self.sessionId = sessionId
        self.sessionName = Self.userSessionNameFormatter.sessionName(deviceType: deviceType, sessionDisplayName: sessionDisplayName)
        self.isVerified = isVerified
        
        var lastActivityDateString: String?
        
        if let lastActivityTimestamp = lastActivityTimestamp {
            lastActivityDateString = Self.lastActivityDateFormatter.lastActivityDateString(from: lastActivityTimestamp)
        }
        
        self.lastActivityDateString = lastActivityDateString
        self.lastSeenIPInfo = lastSeenIP
        self.deviceAvatarViewData = DeviceAvatarViewData(deviceType: deviceType, isVerified: nil)
        
        self.isCurrentSessionDisplayMode = isCurrentSessionDisplayMode
    }
}

extension UserSessionCardViewData {
        
    init(userSessionInfo: UserSessionInfo, isCurrentSessionDisplayMode: Bool = false) {
        self.init(sessionId: userSessionInfo.sessionId, sessionDisplayName: userSessionInfo.sessionName, deviceType: userSessionInfo.deviceType, isVerified: userSessionInfo.isVerified, lastActivityTimestamp: userSessionInfo.lastSeenTimestamp, lastSeenIP: userSessionInfo.lastSeenIP, isCurrentSessionDisplayMode: isCurrentSessionDisplayMode)
    }
}
