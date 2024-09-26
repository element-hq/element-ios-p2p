// File created from SimpleUserProfileExample
// $ createScreen.sh Spaces/SpaceCreation/SpaceCreationEmailInvites SpaceCreationEmailInvites
// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine

class MockSpaceCreationEmailInvitesService: SpaceCreationEmailInvitesServiceProtocol {
    var isLoadingSubject: CurrentValueSubject<Bool, Never>
    
    private let defaultValidation: Bool
    
    var isIdentityServiceReady: Bool {
        return true
    }
    
    init(defaultValidation: Bool, isLoading: Bool) {
        self.defaultValidation = defaultValidation
        self.isLoadingSubject = CurrentValueSubject(isLoading)
    }
    
    func validate(_ emailAddresses: [String]) -> [Bool] {
        return emailAddresses.map { _ in defaultValidation }
    }
    
    func prepareIdentityService(prepared: ((String?, String?) -> Void)?, failure: ((Error?) -> Void)?) {
        failure?(nil)
    }
}
