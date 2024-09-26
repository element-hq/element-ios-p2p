//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import DesignKit

/// Avatar view for device
struct DeviceAvatarView: View {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: DeviceAvatarViewData
        
    var avatarSize: CGFloat = 40
    var badgeSize: CGFloat = 24
    
    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            
            // Device image
            VStack(alignment: .center) {
                viewData.deviceType.image
            }
            .padding()
            .frame(maxWidth: CGFloat(avatarSize), maxHeight: CGFloat(avatarSize))
            .background(theme.colors.system)
            .clipShape(Circle())
            
            // Verification badge
            if let isVerified = viewData.isVerified {
                
                Image(isVerified ? Asset.Images.userSessionVerified.name : Asset.Images.userSessionUnverified.name)
                    .frame(maxWidth: CGFloat(badgeSize), maxHeight: CGFloat(badgeSize))
                    .shapedBorder(color: theme.colors.system, borderWidth: 1, shape: Circle())
                    .background(theme.colors.background)
                    .clipShape(Circle())
                    .offset(x: 10, y: 8)
            }
        }
        .frame(maxWidth: CGFloat(avatarSize), maxHeight: CGFloat(avatarSize))
    }
}

struct DeviceAvatarViewListPreview: View {
    
    var viewDataList: [DeviceAvatarViewData] {
        return [
            DeviceAvatarViewData(deviceType: .desktop, isVerified: true),
            DeviceAvatarViewData(deviceType: .web, isVerified: true),
            DeviceAvatarViewData(deviceType: .mobile, isVerified: true),
            DeviceAvatarViewData(deviceType: .unknown, isVerified: true)
        ]
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .center, spacing: 20) {
                DeviceAvatarView(viewData: DeviceAvatarViewData.init(deviceType: .web, isVerified: true))
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .desktop, isVerified: false))
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .mobile, isVerified: true))
                DeviceAvatarView(viewData: DeviceAvatarViewData(deviceType: .unknown, isVerified: false))
            }
        }
    }
}

struct DeviceAvatarView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            DeviceAvatarViewListPreview().theme(.light).preferredColorScheme(.light)
            DeviceAvatarViewListPreview().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
