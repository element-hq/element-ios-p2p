// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

class MockRoomUpgradeService: RoomUpgradeServiceProtocol {
    var currentRoomId: String = "!sfdlksjdflkfjds:matrix.org"
    
    var errorSubject: CurrentValueSubject<Error?, Never>
    var upgradingSubject: CurrentValueSubject<Bool, Never>
    var parentSpaceName: String? {
        return "Parent space name"
    }
    
    init() {
        self.errorSubject = CurrentValueSubject(nil)
        self.upgradingSubject = CurrentValueSubject(false)
    }
    
    func upgradeRoom(autoInviteUsers: Bool, completion: @escaping (Bool, String) -> Void) {
        
    }
}
