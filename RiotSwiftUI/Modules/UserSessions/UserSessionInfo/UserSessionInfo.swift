// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Represents a user session information
struct UserSessionInfo: Identifiable {
        
    /// Delay after which session is considered inactive, 90 days
    static let inactiveSessionDurationTreshold: TimeInterval = 90 * 86400
    
    // MARK: - Properties
    
    var id: String {
        return sessionId
    }
    
    /// The session identifier
    let sessionId: String

    /// The session display name
    let sessionName: String?
    
    /// The device type used by the session
    let deviceType: DeviceType
    
    /// True to indicate that the session is verified
    let isVerified: Bool
    
    /// The IP address where this device was last seen.
    let lastSeenIP: String?
    
    /// Last time the session was active
    let lastSeenTimestamp: TimeInterval?
        
    /// True to indicate that session has been used under `inactiveSessionDurationTreshold` value
    let isSessionActive: Bool
    
    // MARK: - Setup
    
    init(sessionId: String,
         sessionName: String?,
         deviceType: DeviceType,
         isVerified: Bool,
         lastSeenIP: String?,
         lastSeenTimestamp: TimeInterval?) {
        
        self.sessionId = sessionId
        self.sessionName = sessionName
        self.deviceType = deviceType
        self.isVerified = isVerified
        self.lastSeenIP = lastSeenIP
        self.lastSeenTimestamp = lastSeenTimestamp
        
        if let lastSeenTimestamp = lastSeenTimestamp {
            let elapsedTime = Date().timeIntervalSince1970 - lastSeenTimestamp
            
            let isSessionInactive = elapsedTime >= Self.inactiveSessionDurationTreshold

            self.isSessionActive = !isSessionInactive
        } else {
            self.isSessionActive = true
        }
    }
}
