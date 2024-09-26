// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum UserSuggestionViewAction {
    case selectedItem(UserSuggestionViewStateItem)
}

enum UserSuggestionViewModelResult {
    case selectedItemWithIdentifier(String)
}

struct UserSuggestionViewStateItem: Identifiable {
    let id: String
    let avatar: AvatarInputProtocol?
    let displayName: String?
}

struct UserSuggestionViewState: BindableState {
    var items: [UserSuggestionViewStateItem]
}
