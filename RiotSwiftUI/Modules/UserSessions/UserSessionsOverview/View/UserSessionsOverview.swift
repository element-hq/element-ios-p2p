// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSessionsOverview: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    @ViewBuilder
    private var currentSessionsSection: some View {
        if let currentSessionViewData = viewModel.viewState.currentSessionViewData {
            SwiftUI.Section {
                UserSessionCardView(viewData: currentSessionViewData, onVerifyAction: { _ in
                    viewModel.send(viewAction: .verifyCurrentSession)
                }, onViewDetailsAction: { _ in
                    viewModel.send(viewAction: .viewCurrentSessionDetails)
                })
                .padding(.horizontal, 16)
            } header: {
                Text(VectorL10n.userSessionsOverviewCurrentSessionSectionTitle)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 24)
                    .padding(.bottom, 11)
            }
        }
    }
    
    // MARK: Public
    
    @ObservedObject var viewModel: UserSessionsOverviewViewModel.Context
    
    var body: some View {
        ScrollView {
            
            // Security recommendations section
            if viewModel.viewState.unverifiedSessionsViewData.isEmpty == false || viewModel.viewState.inactiveSessionsViewData.isEmpty == false {
                
                // TODO:
            }
            
            // Current session section
            currentSessionsSection
            
            // Other sessions section
            if viewModel.viewState.otherSessionsViewData.isEmpty == false {
                self.otherSessionsSection
            }
        }
        .background(theme.colors.system.ignoresSafeArea())
        .frame(maxHeight: .infinity)
        .navigationTitle(VectorL10n.userSessionsOverviewTitle)
        .activityIndicator(show: viewModel.viewState.showLoadingIndicator)
        .onAppear() {
            viewModel.send(viewAction: .viewAppeared)
        }
    }
    
    private var otherSessionsSection: some View {
        
        SwiftUI.Section {
            // Device list
            LazyVStack(spacing: 0) {
                ForEach(viewModel.viewState.otherSessionsViewData) { viewData in
                    UserSessionListItem(viewData: viewData, onBackgroundTap: { sessionId in
                        viewModel.send(viewAction: .tapUserSession(sessionId))
                    })
                }
            }
            .background(theme.colors.background)
        } header: {
            VStack(alignment: .leading) {
                Text(VectorL10n.userSessionsOverviewOtherSessionsSectionTitle)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .padding(.bottom, 10)
                
                Text(VectorL10n.userSessionsOverviewOtherSessionsSectionInfo)
                    .font(theme.fonts.footnote)
                    .foregroundColor(theme.colors.secondaryContent)
                    .padding(.bottom, 11)
            }
            .padding(.horizontal, 16)
            .padding(.top, 24)
        }
    }
}

// MARK: - Previews

struct UserSessionsOverview_Previews: PreviewProvider {
    static let stateRenderer = MockUserSessionsOverviewScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
