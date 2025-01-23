// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSuggestionListItem: View {
    
    // MARK: - Properties
    
    // MARK: Private
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    let avatar: AvatarInputProtocol?
    let displayName: String?
    let userId: String
    
    var body: some View {
        HStack {
            if let avatar = avatar {
                AvatarImage(avatarData: avatar, size: .medium)
            }
            VStack(alignment: .leading) {
                Text(displayName ?? "")
                    .font(theme.fonts.body)
                    .foregroundColor(theme.colors.primaryContent)
                    .accessibility(identifier: "displayNameText")
                    .lineLimit(1)
                Text(userId)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.tertiaryContent)
                    .accessibility(identifier: "userIdText")
                    .lineLimit(1)
            }
        }
    }
}

// MARK: - Previews

struct UserSuggestionHeader_Previews: PreviewProvider {
    static var previews: some View {
        UserSuggestionListItem(avatar: MockAvatarInput.example, displayName: "Alice", userId: "@alice:matrix.org")
            .addDependency(MockAvatarService.example)
    }
}
