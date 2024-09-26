// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine

struct RoomMembersProviderMember {
    var userId: String
    var displayName: String
    var avatarUrl: String
}

protocol RoomMembersProviderProtocol {
    func fetchMembers(_ members: @escaping ([RoomMembersProviderMember]) -> Void)
}

struct UserSuggestionServiceItem: UserSuggestionItemProtocol {
    let userId: String
    let displayName: String?
    let avatarUrl: String?
}

class UserSuggestionService: UserSuggestionServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let roomMemberProvider: RoomMembersProviderProtocol
    
    private var suggestionItems: [UserSuggestionItemProtocol] = []
    private let currentTextTriggerSubject = CurrentValueSubject<String?, Never>(nil)
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Public
    
    var items = CurrentValueSubject<[UserSuggestionItemProtocol], Never>([])
    
    var currentTextTrigger: String? {
        currentTextTriggerSubject.value
    }
    
    // MARK: - Setup
    
    init(roomMemberProvider: RoomMembersProviderProtocol, shouldDebounce: Bool = true) {
        self.roomMemberProvider = roomMemberProvider
        
        if (shouldDebounce) {
            currentTextTriggerSubject
                .debounce(for: 0.5, scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { [weak self] in self?.fetchAndFilterMembersForTextTrigger($0) }
                .store(in: &cancellables)
        } else {
            currentTextTriggerSubject
                .sink { [weak self] in self?.fetchAndFilterMembersForTextTrigger($0) }
                .store(in: &cancellables)
        }
    }
    
    // MARK: - UserSuggestionServiceProtocol
    
    func processTextMessage(_ textMessage: String?) {
        guard let textMessage = textMessage,
              textMessage.count > 0,
              let lastComponent = textMessage.components(separatedBy: .whitespaces).last,
              lastComponent.prefix(while: { $0 == "@" }).count == 1 // Partial username should start with one and only one "@" character
        else {
            self.items.send([])
            self.currentTextTriggerSubject.send(nil)
            return
        }
        
        self.currentTextTriggerSubject.send(lastComponent)
    }
    
    // MARK: - Private
    
    private func fetchAndFilterMembersForTextTrigger(_ textTrigger: String?) {
        guard var partialName = textTrigger else {
            return
        }
        
        partialName.removeFirst() // remove the '@' prefix
        
        roomMemberProvider.fetchMembers { [weak self] members in
            guard let self = self else {
                return
            }
            
            self.suggestionItems = members.map { member in
                UserSuggestionServiceItem(userId: member.userId, displayName: member.displayName, avatarUrl: member.avatarUrl)
            }
            
            self.items.send(self.suggestionItems.filter({ userSuggestion in
                let containedInUsername = userSuggestion.userId.lowercased().contains(partialName.lowercased())
                let containedInDisplayName = (userSuggestion.displayName ?? "").lowercased().contains(partialName.lowercased())
                
                return (containedInUsername || containedInDisplayName)
            }))
        }
    }
}
