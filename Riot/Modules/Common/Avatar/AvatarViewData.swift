// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct AvatarViewData: AvatarViewDataProtocol {
    /// Matrix item identifier (user id or room id)
    var matrixItemId: String
    
    /// Matrix item display name (user or room display name)
    var displayName: String?

    /// Matrix item avatar URL (user or room avatar url)
    var avatarUrl: String?
        
    /// Matrix media handler if exists
    var mediaManager: MXMediaManager?
    
    /// Fallback image used when avatarUrl is nil
    var fallbackImage: AvatarFallbackImage?
}
