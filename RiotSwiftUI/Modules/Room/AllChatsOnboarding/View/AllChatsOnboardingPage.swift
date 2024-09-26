// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct AllChatsOnboardingPage: View {

    // MARK: - Properties
    
    let image: UIImage
    let title: String
    let message: String
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    var body: some View {
        VStack {
            Spacer()
            Image(uiImage: image)
            Spacer()
            Text(title)
                .font(theme.fonts.title2B)
                .foregroundColor(theme.colors.primaryContent)
                .padding(.bottom, 16)
            Text(message)
                .multilineTextAlignment(.center)
                .font(theme.fonts.callout)
                .foregroundColor(theme.colors.primaryContent)
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Previews

struct AllChatsOnboardingPage_Previews: PreviewProvider {
    static var previews: some View {
        preview.theme(.light).preferredColorScheme(.light)
        preview.theme(.dark).preferredColorScheme(.dark)
    }
    
    static private var preview: some View {
        AllChatsOnboardingPage(image: Asset.Images.allChatsOnboarding1.image,
                               title: VectorL10n.allChatsOnboardingPageTitle1,
                               message: VectorL10n.allChatsOnboardingPageMessage1)
    }
}
