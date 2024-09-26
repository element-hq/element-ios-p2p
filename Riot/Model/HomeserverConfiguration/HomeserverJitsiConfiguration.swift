// 
// Copyright 2020-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// `HomeserverJitsiConfiguration` gives Jitsi widget configuration used by homeserver
@objcMembers
final class HomeserverJitsiConfiguration: NSObject {
    let serverDomain: String?
    let serverURL: URL?
    
    init(serverDomain: String?, serverURL: URL?) {
        self.serverDomain = serverDomain
        self.serverURL = serverURL
        
        super.init()
    }
}
