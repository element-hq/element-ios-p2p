// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

// MARK: View model

enum UserSessionsOverviewViewModelResult {
    case cancel
    case showAllUnverifiedSessions
    case showAllInactiveSessions
    case verifyCurrentSession
    case showCurrentSessionDetails
    case showAllOtherSessions
    case showUserSessionDetails(_ sessionId: String)
}

// MARK: View

struct UserSessionsOverviewViewState: BindableState {
    
    var unverifiedSessionsViewData: [UserSessionListItemViewData]
    
    var inactiveSessionsViewData: [UserSessionListItemViewData]
    
    var currentSessionViewData: UserSessionCardViewData?
    
    var otherSessionsViewData: [UserSessionListItemViewData]
    
    var showLoadingIndicator: Bool = false
}

enum UserSessionsOverviewViewAction {
    case viewAppeared
    case verifyCurrentSession
    case viewCurrentSessionDetails
    case viewAllUnverifiedSessions
    case viewAllInactiveSessions
    case viewAllOtherSessions
    case tapUserSession(_ sessionId: String)
}
