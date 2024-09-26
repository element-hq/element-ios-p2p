// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

enum MockUserSuggestionScreenState: MockScreenState, CaseIterable {
    case multipleResults
    
    static private var members: [RoomMembersProviderMember]!
    
    var screenType: Any.Type {
        UserSuggestionList.self
    }
    
    var screenView: ([Any], AnyView)  {
        let service = UserSuggestionService(roomMemberProvider: self)
        let listViewModel = UserSuggestionViewModel(userSuggestionService: service)
        
        let viewModel = UserSuggestionListWithInputViewModel(listViewModel: listViewModel) { textMessage in
            service.processTextMessage(textMessage)
        }
        
        return (
            [service, listViewModel],
            AnyView(UserSuggestionListWithInput(viewModel: viewModel)
                        .addDependency(MockAvatarService.example))
        )
    }
}

extension MockUserSuggestionScreenState: RoomMembersProviderProtocol {
    func fetchMembers(_ members: ([RoomMembersProviderMember]) -> Void) {
        if Self.members == nil {
            Self.members = generateUsersWithCount(10)
        }
        
        members(Self.members)
    }
    
    private func generateUsersWithCount(_ count: UInt) -> [RoomMembersProviderMember] {
        return (0..<count).map { _ in
            let identifier = "@" + UUID().uuidString
            return RoomMembersProviderMember(userId: identifier, displayName: identifier, avatarUrl: "mxc://matrix.org/VyNYAgahaiAzUoOeZETtQ")
        }
    }
}
