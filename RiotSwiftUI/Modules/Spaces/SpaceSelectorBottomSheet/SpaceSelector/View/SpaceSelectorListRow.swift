// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SpaceSelectorListRow: View {
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    let avatar: AvatarInputProtocol?
    let icon: UIImage?
    let displayName: String?
    let hasSubItems: Bool
    let isJoined: Bool
    let isSelected: Bool
    let notificationCount: UInt
    let highlightedNotificationCount: UInt
    let disclosureAction: (() -> Void)?
    
    @ViewBuilder
    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(theme.colors.system)
                    .padding(.horizontal, 8)
            }
            VStack {
                HStack {
                    if let avatar = avatar {
                        SpaceAvatarImage(avatarData: avatar, size: .xSmall)
                    }
                    if let icon = icon {
                        Image(uiImage: icon)
                            .renderingMode(.template)
                            .foregroundColor(theme.colors.primaryContent)
                            .frame(width: 32, height: 32)
                            .background(theme.colors.quinaryContent)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    Text(displayName ?? "")
                        .foregroundColor(theme.colors.primaryContent)
                        .font(theme.fonts.bodySB)
                        .accessibility(identifier: "itemName")
                    Spacer()
                    if notificationCount > 0 {
                        badge(with: "\(notificationCount)", color: highlightedNotificationCount > 0 ? theme.colors.alert : theme.colors.secondaryContent)
                    }
                    if !isJoined {
                        badge(with: "! ", color: theme.colors.alert)
                        Image(systemName: "chevron.right")
                            .renderingMode(.template)
                            .foregroundColor(theme.colors.secondaryContent)
                    }
                    if hasSubItems && isJoined {
                        Button {
                            disclosureAction?()
                        } label: {
                            Image(systemName: "chevron.right")
                                .renderingMode(.template)
                                .foregroundColor(theme.colors.accent)
                        }
                        .accessibility(identifier: "disclosureButton")
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.horizontal)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background(theme.colors.background)
    }

    private func badge(with text: String, color: Color) -> some View {
        return Text(text)
            .multilineTextAlignment(.center)
            .foregroundColor(theme.colors.background)
            .font(theme.fonts.footnote)
            .padding(.vertical, 2)
            .padding(.horizontal, 6)
            .background(color)
            .clipShape(Capsule())
            .accessibility(identifier: "notificationBadge")
    }
}

// MARK: - Previews

struct SpaceSelectorListRow_Previews: PreviewProvider {
    
    static var previews: some View {
        sampleView.theme(.light).preferredColorScheme(.light)
        sampleView.theme(.dark).preferredColorScheme(.dark)
    }
    
    static var sampleView: some View {
        VStack(spacing: 8) {
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: false, isJoined: true, isSelected: false, notificationCount: 0, highlightedNotificationCount: 0, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: true, isJoined: true, isSelected: false, notificationCount: 0, highlightedNotificationCount: 0, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: true, isJoined: true, isSelected: false, notificationCount: 99, highlightedNotificationCount: 0, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: false, isJoined: true, isSelected: false, notificationCount: 99, highlightedNotificationCount: 1, disclosureAction: nil)
            SpaceSelectorListRow(avatar: nil, icon: UIImage(systemName: "house"), displayName: "Space name", hasSubItems: true, isJoined: true, isSelected: true, notificationCount: 99, highlightedNotificationCount: 1, disclosureAction: nil)
        }
    }
    
}
