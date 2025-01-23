//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import DesignKit

struct UserSessionCardView: View {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    var viewData: UserSessionCardViewData
    
    var onVerifyAction: ((String) -> (Void))? = nil
    var onViewDetailsAction: ((String) -> (Void))? = nil
    var onLearnMoreAction: (() -> (Void))? = nil
    
    private var verificationStatusImageName: String {
        return viewData.isVerified ? Asset.Images.userSessionVerified.name : Asset.Images.userSessionUnverified.name
    }
    
    private var verificationStatusText: String {
        return viewData.isVerified ? VectorL10n.userSessionVerified : VectorL10n.userSessionUnverified
    }
    
    private var verificationStatusColor: Color {
        return viewData.isVerified ? theme.colors.accent : theme.colors.alert
    }
    
    private var verificationStatusAdditionalInfoText: String {
        return viewData.isVerified ? VectorL10n.userSessionVerifiedAdditionalInfo : VectorL10n.userSessionUnverifiedAdditionalInfo
    }
    
    private var backgroundShape: RoundedRectangle {
        return RoundedRectangle(cornerRadius: 8)
    }
    
    private var showExtraInformations: Bool {
        return viewData.isCurrentSessionDisplayMode == false && (viewData.lastActivityDateString.isEmptyOrNil == false || viewData.lastSeenIPInfo.isEmptyOrNil == false)
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 12) {
            DeviceAvatarView(viewData: viewData.deviceAvatarViewData)
            
            Text(viewData.sessionName)
                .font(theme.fonts.headline)
                .foregroundColor(theme.colors.primaryContent)
                .multilineTextAlignment(.center)
            
            HStack {
                Image(verificationStatusImageName)
                Text(verificationStatusText)
                    .font(theme.fonts.subheadline)
                    .foregroundColor(verificationStatusColor)
                    .multilineTextAlignment(.center)
            }
            
            if viewData.isCurrentSessionDisplayMode {
                Text(verificationStatusAdditionalInfoText)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .multilineTextAlignment(.center)
            } else {
                InlineTextButton(verificationStatusAdditionalInfoText + " %@", tappableText: VectorL10n.userSessionLearnMore) {
                    onLearnMoreAction?()
                }
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
                .multilineTextAlignment(.center)
            }
            
            if self.showExtraInformations {
                VStack(spacing: 2) {
                    if let lastActivityDateString = viewData.lastActivityDateString, lastActivityDateString.isEmpty == false {
                        Text(lastActivityDateString)
                            .font(theme.fonts.footnote)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.center)
                    }
                    
                    if let lastSeenIPInfo = viewData.lastSeenIPInfo, lastSeenIPInfo.isEmpty == false  {
                        Text(lastSeenIPInfo)
                            .font(theme.fonts.footnote)
                            .foregroundColor(theme.colors.secondaryContent)
                            .multilineTextAlignment(.center)
                    }
                }
            }
            
            if viewData.isVerified == false {
                Button {
                    onVerifyAction?(viewData.sessionId)
                } label: {
                    Text(VectorL10n.userSessionVerifyAction)
                        .font(theme.fonts.body)
                }
                .buttonStyle(PrimaryActionButtonStyle())
                .padding(.top, 4)
                .padding(.bottom, 3)
            }
            
            if viewData.isCurrentSessionDisplayMode {
                Button {
                    onViewDetailsAction?(viewData.sessionId)
                } label: {
                    Text(VectorL10n.userSessionViewDetails)
                        .font(theme.fonts.body)
                        .foregroundColor(theme.colors.accent)
                }
                .padding(.top, 4)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(theme.colors.background)
        .clipShape(self.backgroundShape)
        .shapedBorder(color: theme.colors.quinaryContent, borderWidth: 1.0, shape: self.backgroundShape)
    }
}

struct UserSessionCardViewPreview: View {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    
    let viewData: UserSessionCardViewData
    
    init(isCurrentSessionInfo: Bool = false) {
        let currentSessionInfo = UserSessionInfo(sessionId: "alice", sessionName: "iOS", deviceType: .mobile, isVerified: false, lastSeenIP: "10.0.0.10", lastSeenTimestamp: Date().timeIntervalSince1970 - 100)
        
        viewData = UserSessionCardViewData(userSessionInfo: currentSessionInfo, isCurrentSessionDisplayMode: isCurrentSessionInfo)
    }
    
    var body: some View {
        VStack {
            UserSessionCardView(viewData: self.viewData)
        }
        .frame(maxWidth: .infinity)
        .background(theme.colors.system)
        .padding()
    }
}

struct UserSessionCardView_Previews: PreviewProvider {
    
    static var previews: some View {
        Group {
            UserSessionCardViewPreview(isCurrentSessionInfo: true).theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview(isCurrentSessionInfo: true).theme(.dark).preferredColorScheme(.dark)
            UserSessionCardViewPreview().theme(.light).preferredColorScheme(.light)
            UserSessionCardViewPreview().theme(.dark).preferredColorScheme(.dark)
        }
    }
}
