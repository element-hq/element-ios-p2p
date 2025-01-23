// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// AuthenticatedEndpointRequest represents authenticated API endpoint request.
@objcMembers
class AuthenticatedEndpointRequest: NSObject {
    
    let path: String
    let httpMethod: String
    
    init(path: String, httpMethod: String) {
        self.path = path
        self.httpMethod = httpMethod
        super.init()
    }
}
