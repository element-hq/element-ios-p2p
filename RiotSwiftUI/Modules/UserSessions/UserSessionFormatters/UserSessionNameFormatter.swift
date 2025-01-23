// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Enables to build user session name
class UserSessionNameFormatter {
    
    /// Session name with client name and session display name
    func sessionName(deviceType: DeviceType, sessionDisplayName: String?) -> String {
        
        let sessionName: String
        
        let clientName = deviceType.name
        
        if let sessionDisplayName = sessionDisplayName {
            sessionName = VectorL10n.userSessionName(clientName, sessionDisplayName)
        } else {
            sessionName = clientName
        }
        
        return sessionName
    }
}
