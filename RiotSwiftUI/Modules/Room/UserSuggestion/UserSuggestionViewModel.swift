// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Combine

typealias UserSuggestionViewModelType = StateStoreViewModel <UserSuggestionViewState,
                                                             Never,
                                                             UserSuggestionViewAction>

class UserSuggestionViewModel: UserSuggestionViewModelType, UserSuggestionViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let userSuggestionService: UserSuggestionServiceProtocol
    
    // MARK: Public
    
    var completion: ((UserSuggestionViewModelResult) -> Void)?
    
    // MARK: - Setup
    
    init(userSuggestionService: UserSuggestionServiceProtocol) {
        self.userSuggestionService = userSuggestionService
        
        let items = userSuggestionService.items.value.map { suggestionItem in
            return UserSuggestionViewStateItem(id: suggestionItem.userId, avatar: suggestionItem, displayName: suggestionItem.displayName)
        }
        
        super.init(initialViewState: UserSuggestionViewState(items: items))
        
        userSuggestionService.items.sink { [weak self] items in
            self?.state.items = items.map({ item in
                UserSuggestionViewStateItem(id: item.userId, avatar: item, displayName: item.displayName)
            })
        }.store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserSuggestionViewAction) {
        switch viewAction {
        case .selectedItem(let item):
            completion?(.selectedItemWithIdentifier(item.id))
        }
    }
}
