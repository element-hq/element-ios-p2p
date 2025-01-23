//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// View data for UserSessionListItem
struct UserSessionListItemViewData: Identifiable {
    
    // MARK: - Constants
    
    private static let userSessionNameFormatter = UserSessionNameFormatter()
    private static let lastActivityDateFormatter = UserSessionLastActivityFormatter()
    
    // MARK: - Properties
    
    var id: String {
        return sessionId
    }
    
    let sessionId: String

    let sessionName: String
    
    let sessionDetails: String
    
    let deviceAvatarViewData: DeviceAvatarViewData
    
    // MARK: - Setup
    
    init(sessionId: String,
         sessionDisplayName: String?,
         deviceType: DeviceType,
         isVerified: Bool,
         lastActivityDate: TimeInterval?) {
                
        self.sessionId = sessionId
        self.sessionName = Self.userSessionNameFormatter.sessionName(deviceType: deviceType, sessionDisplayName: sessionDisplayName)
        self.sessionDetails = Self.buildSessionDetails(isVerified: isVerified, lastActivityDate: lastActivityDate)
        self.deviceAvatarViewData = DeviceAvatarViewData(deviceType: deviceType, isVerified: isVerified)
    }
    
    // MARK: - Private
    
    private static func buildSessionDetails(isVerified: Bool, lastActivityDate: TimeInterval?) -> String {
        
        let sessionDetailsString: String
        
        let sessionStatusText = isVerified ? VectorL10n.userSessionVerifiedShort : VectorL10n.userSessionUnverifiedShort
        
        var lastActivityDateString: String?
        
        if let lastActivityDate = lastActivityDate {
            lastActivityDateString = Self.lastActivityDateFormatter.lastActivityDateString(from: lastActivityDate)
        }

        if let lastActivityDateString = lastActivityDateString, lastActivityDateString.isEmpty == false {
            sessionDetailsString = VectorL10n.userSessionItemDetails(sessionStatusText, lastActivityDateString)
        } else {
            sessionDetailsString = sessionStatusText
        }
        
        return sessionDetailsString
    }
}

extension UserSessionListItemViewData {
        
    init(userSessionInfo: UserSessionInfo) {
        self.init(sessionId: userSessionInfo.sessionId, sessionDisplayName: userSessionInfo.sessionName, deviceType: userSessionInfo.deviceType, isVerified: userSessionInfo.isVerified, lastActivityDate: userSessionInfo.lastSeenTimestamp)
    }
}
