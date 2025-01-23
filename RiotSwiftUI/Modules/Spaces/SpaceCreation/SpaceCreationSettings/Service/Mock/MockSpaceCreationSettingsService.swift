// File created from TemplateAdvancedRoomsExample
// $ createSwiftUITwoScreen.sh Spaces/SpaceCreation SpaceCreation SpaceCreationMenu SpaceCreationSettings
// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

class MockSpaceCreationSettingsService: SpaceCreationSettingsServiceProtocol {
    

    var addressValidationSubject: CurrentValueSubject<SpaceCreationSettingsAddressValidationStatus, Never>
    var avatarViewDataSubject: CurrentValueSubject<AvatarInputProtocol, Never>
    var defaultAddressSubject: CurrentValueSubject<String, Never>
    var spaceAddress: String?
    var roomName: String
    var userDefinedAddress: String?
    var isAddressValid: Bool = true

    init() {
        roomName = "Fake"
        defaultAddressSubject = CurrentValueSubject("fake-uri")
        addressValidationSubject = CurrentValueSubject(.none("#fake-uri:fake-domain.org"))
        avatarViewDataSubject = CurrentValueSubject(AvatarInput(mxContentUri: defaultAddressSubject.value, matrixItemId: "", displayName: roomName))
    }
    
    func simulateUpdate(addressValidationStatus: SpaceCreationSettingsAddressValidationStatus) {
        self.addressValidationSubject.value = addressValidationStatus
    }
    
//    func simulateUpdate()
}
