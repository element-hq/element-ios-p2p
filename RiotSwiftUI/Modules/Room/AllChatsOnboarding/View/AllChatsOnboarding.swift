// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct AllChatsOnboarding: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    @State private var selectedTab = 0
    
    // MARK: Public
    
    @ObservedObject var viewModel: AllChatsOnboardingViewModel.Context
    
    var body: some View {
        VStack {
            Text(VectorL10n.allChatsOnboardingTitle)
                .font(theme.fonts.title3SB)
                .foregroundColor(theme.colors.primaryContent)
                .padding()
            TabView(selection: $selectedTab) {
                ForEach(viewModel.viewState.pages.indices) { index in
                    let page = viewModel.viewState.pages[index]
                    AllChatsOnboardingPage(image: page.image,
                                           title: page.title,
                                           message: page.message)
                    .tag(index)
                }
            }
            .tabViewStyle(PageTabViewStyle(indexDisplayMode: .automatic))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            Button { onCallToAction() } label: {
                Text(selectedTab == viewModel.viewState.pages.count - 1 ? VectorL10n.allChatsOnboardingTryIt : VectorL10n.next)
                    .animation(nil)
            }
            .buttonStyle(PrimaryActionButtonStyle())
            .padding()
        }
        .background(theme.colors.background.ignoresSafeArea())
        .frame(maxHeight: .infinity)
    }

    // MARK: - Private
    
    private func onCallToAction() {
        if (selectedTab == viewModel.viewState.pages.count - 1) {
            viewModel.send(viewAction: .cancel)
        } else {
            withAnimation {
                selectedTab += 1
            }
        }
    }
}

// MARK: - Previews

struct AllChatsOnboarding_Previews: PreviewProvider {
    static var previews: some View {
        AllChatsOnboarding(viewModel: AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel().context).theme(.light).preferredColorScheme(.light)
        AllChatsOnboarding(viewModel: AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel().context).theme(.dark).preferredColorScheme(.dark)
    }
}
