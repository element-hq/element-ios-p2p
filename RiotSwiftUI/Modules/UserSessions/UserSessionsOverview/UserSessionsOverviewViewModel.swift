//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

typealias UserSessionsOverviewViewModelType = StateStoreViewModel<UserSessionsOverviewViewState,
                                                                 Never,
                                                                 UserSessionsOverviewViewAction>

class UserSessionsOverviewViewModel: UserSessionsOverviewViewModelType, UserSessionsOverviewViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let userSessionsOverviewService: UserSessionsOverviewServiceProtocol

    // MARK: Public

    var completion: ((UserSessionsOverviewViewModelResult) -> Void)?

    // MARK: - Setup

    init(userSessionsOverviewService: UserSessionsOverviewServiceProtocol) {
        self.userSessionsOverviewService = userSessionsOverviewService
        
        let initialViewState = UserSessionsOverviewViewState(unverifiedSessionsViewData: [], inactiveSessionsViewData: [], currentSessionViewData: nil, otherSessionsViewData: [])
        
        super.init(initialViewState: initialViewState)
        
        self.updateViewState(with: userSessionsOverviewService.lastOverviewData)
    }
    
    // MARK: - Public

    override func process(viewAction: UserSessionsOverviewViewAction) {
        switch viewAction {
        case .viewAppeared:
            self.loadData()
        case .verifyCurrentSession:
            self.completion?(.verifyCurrentSession)
        case .viewCurrentSessionDetails:
            self.completion?(.showCurrentSessionDetails)
        case .viewAllUnverifiedSessions:
            self.completion?(.showAllUnverifiedSessions)
        case .viewAllInactiveSessions:
            self.completion?(.showAllInactiveSessions)
        case .viewAllOtherSessions:
            self.completion?(.showAllOtherSessions)
        case .tapUserSession(let sessionId):
            self.completion?(.showUserSessionDetails(sessionId))
        }
    }
    
    // MARK: - Private
    
    private func updateViewState(with userSessionsViewData: UserSessionsOverviewData) {
        
        let unverifiedSessionsViewData = self.userSessionListItemViewDataList(from: userSessionsViewData.unverifiedSessionsInfo)
        let inactiveSessionsViewData = self.userSessionListItemViewDataList(from: userSessionsViewData.inactiveSessionsInfo)
        
        var currentSessionViewData: UserSessionCardViewData?
        
        let otherSessionsViewData = self.userSessionListItemViewDataList(from: userSessionsViewData.otherSessionsInfo)
         
        
        if let currentSessionInfo = userSessionsViewData.currentSessionInfo {
            currentSessionViewData = UserSessionCardViewData(userSessionInfo: currentSessionInfo, isCurrentSessionDisplayMode: true)
        }
     
        self.state.unverifiedSessionsViewData = unverifiedSessionsViewData
        self.state.inactiveSessionsViewData = inactiveSessionsViewData
        self.state.currentSessionViewData = currentSessionViewData
        self.state.otherSessionsViewData = otherSessionsViewData
    }

    private func userSessionListItemViewDataList(from userSessionInfoList: [UserSessionInfo]) -> [UserSessionListItemViewData] {
        return userSessionInfoList.map {
            return UserSessionListItemViewData(userSessionInfo: $0)
        }
    }
    
    private func loadData() {
        
        self.state.showLoadingIndicator = true
        
        self.userSessionsOverviewService.fetchUserSessionsOverviewData { [weak self] result in
            guard let self = self else {
                return
            }
            
            self.state.showLoadingIndicator = false
            
            switch result {
            case .success(let overViewData):
                self.updateViewState(with: overViewData)
            case .failure(let error):
                // TODO
                break
            }
        }
    }
}
