// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import CoreLocation

/// Represents user live location
struct UserLiveLocation {
    
    var userId: String {
        return avatarData.matrixItemId
    }
    
    var displayName: String {
        return avatarData.displayName ?? self.userId
    }
    
    let avatarData: AvatarInputProtocol
    
    /// Location sharing start date
    let timestamp: TimeInterval
    
    /// Sharing duration from the start sharing date
    let timeout: TimeInterval

    /// Last coordinatore update date
    let lastUpdate: TimeInterval
    
    let coordinate: CLLocationCoordinate2D
}
