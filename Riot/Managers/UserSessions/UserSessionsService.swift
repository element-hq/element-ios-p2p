// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

// MARK: - UserSessionsService notification constants
extension UserSessionsService {
    public static let didAddUserSession = Notification.Name("UserSessionsServiceDidAddUserSession")
    public static let willRemoveUserSession = Notification.Name("UserSessionsServiceWillRemoveUserSession")
    public static let didRemoveUserSession = Notification.Name("UserSessionsServiceDidRemoveUserSession")
    public static let userSessionDidChange = Notification.Name("UserSessionsServiceUserSessionDidChange")
    
    public struct NotificationUserInfoKey {
        static let userSession = "userSession"
        static let userId = "userId"
    }
}

/// UserSessionsService enables to manage multiple user sessions and all logic around sessions management.
/// TODO: Move MXSession and MXKAccountManager code from LegacyAppDelegate to this place. Create a UserSessionService to make per session management if needed.
@objcMembers
class UserSessionsService: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private(set) var userSessions: [UserSession] = []
    private var accountManager: MXKAccountManager = MXKAccountManager.shared()
    
    // MARK: Public
    
    /// At the moment the main session is the first one added
    var mainUserSession: UserSession? {
        return self.userSessions.first
    }
    
    // MARK: - Setup
    
    override init() {
        super.init()
        
        for account in self.accountManager.accounts {
            self.addUserSession(fromAccount: account, postNotification: false)
        }
        
        self.registerAccountNotifications()
    }
    
    // MARK: - Public
    
    func addUserSession(fromAccount account: MXKAccount) {
        self.addUserSession(fromAccount: account, postNotification: true)
    }
    
    func removeUserSession(relatedToAccount account: MXKAccount) {
        self.removeUserSession(relatedToAccount: account, postNotification: true)
    }
    
    func isUserSessionExists(withUserId userId: String) -> Bool {
        return self.userSessions.contains { (userSession) -> Bool in
            return userSession.userId == userId
        }
    }
    
    func userSession(withUserId userId: String) -> UserSession? {
        return self.userSessions.first { (userSession) -> Bool in
            return userSession.userId == userId
        }
    }
    
    // MARK: - Private
    
    private func addUserSession(fromAccount account: MXKAccount, postNotification: Bool) {
        guard let userId = account.mxCredentials.userId, !self.isUserSessionExists(withUserId: userId) else {
            return
        }
        
        let userSession = UserSession(account: account)
        self.userSessions.append(userSession)
                
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.didAddUserSession, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
    }
    
    private func removeUserSession(relatedToAccount account: MXKAccount, postNotification: Bool) {
        guard let userId = account.mxCredentials.userId, !self.isUserSessionExists(withUserId: userId) else {
            return
        }
        
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.willRemoveUserSession, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
        
        self.userSessions.removeAll { (userSession) -> Bool in
            return userId == userSession.userId
        }
        
        if postNotification {
            NotificationCenter.default.post(name: UserSessionsService.didRemoveUserSession, object: self, userInfo: [NotificationUserInfoKey.userId: userId])
        }
    }
    
    private func registerAccountNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(accountDidChange(_:)), name: .mxkAccountUserInfoDidChange, object: nil)
    }
    
    @objc private func accountDidChange(_ notification: Notification) {
        guard let userId = notification.object as? String else {
            return
        }
        
        if let userSession = self.userSession(withUserId: userId) {
            NotificationCenter.default.post(name: UserSessionsService.userSessionDidChange, object: self, userInfo: [NotificationUserInfoKey.userSession: userSession])
        }
    }
}
