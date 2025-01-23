// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MockUserSessionsOverviewService: UserSessionsOverviewServiceProtocol {
    
    var lastOverviewData: UserSessionsOverviewData
    
    func fetchUserSessionsOverviewData(completion: @escaping (Result<UserSessionsOverviewData, Error>) -> Void) {
        completion(.success(self.lastOverviewData))
    }
    
    init() {
        let currentSessionInfo = UserSessionInfo(sessionId: "alice", sessionName: "iOS", deviceType: .mobile, isVerified: false, lastSeenIP: "10.0.0.10", lastSeenTimestamp: nil)
        
        let unverifiedSessionsInfo: [UserSessionInfo] = []
        
        let inactiveSessionsInfo: [UserSessionInfo] = []
        
        let otherSessionsInfo: [UserSessionInfo] = [
            UserSessionInfo(sessionId: "1", sessionName: "macOS", deviceType: .desktop, isVerified: true, lastSeenIP: "1.0.0.1", lastSeenTimestamp: (Date().timeIntervalSince1970 - 130000)),
            UserSessionInfo(sessionId: "2", sessionName: "Firefox on Windows", deviceType: .web, isVerified: true, lastSeenIP: "2.0.0.2", lastSeenTimestamp: (Date().timeIntervalSince1970 - 100)),
            UserSessionInfo(sessionId: "3", sessionName: "Android", deviceType: .mobile, isVerified: false, lastSeenIP: "3.0.0.3", lastSeenTimestamp: (Date().timeIntervalSince1970 - 10))
        ]
        
        self.lastOverviewData = UserSessionsOverviewData(currentSessionInfo: currentSessionInfo, unverifiedSessionsInfo: unverifiedSessionsInfo, inactiveSessionsInfo: inactiveSessionsInfo, otherSessionsInfo: otherSessionsInfo)
    }
}
