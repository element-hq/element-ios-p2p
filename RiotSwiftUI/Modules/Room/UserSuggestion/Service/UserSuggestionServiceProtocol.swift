// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

protocol UserSuggestionItemProtocol: Avatarable {
    var userId: String { get }
    var displayName: String? { get }
    var avatarUrl: String? { get }
}

protocol UserSuggestionServiceProtocol {
    
    var items: CurrentValueSubject<[UserSuggestionItemProtocol], Never> { get }
    
    var currentTextTrigger: String? { get }
    
    func processTextMessage(_ textMessage: String?)
}

// MARK: Avatarable

extension UserSuggestionItemProtocol {
    var mxContentUri: String? {
        avatarUrl
    }
    var matrixItemId: String {
        userId
    }
}
