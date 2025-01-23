// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc
protocol UserSuggestionCoordinatorBridgeDelegate: AnyObject {
    func userSuggestionCoordinatorBridge(_ coordinator: UserSuggestionCoordinatorBridge, didRequestMentionForMember member: MXRoomMember, textTrigger: String?)
    func userSuggestionCoordinatorBridge(_ coordinator: UserSuggestionCoordinatorBridge, didUpdateViewHeight height: CGFloat)
}

@objcMembers
final class UserSuggestionCoordinatorBridge: NSObject {
    
    private var _userSuggestionCoordinator: Any? = nil
    fileprivate var userSuggestionCoordinator: UserSuggestionCoordinator {
        return _userSuggestionCoordinator as! UserSuggestionCoordinator
    }
    
    weak var delegate: UserSuggestionCoordinatorBridgeDelegate?
    
    init(mediaManager: MXMediaManager, room: MXRoom) {
        let parameters = UserSuggestionCoordinatorParameters(mediaManager: mediaManager, room: room)
        let userSuggestionCoordinator = UserSuggestionCoordinator(parameters: parameters)
        self._userSuggestionCoordinator = userSuggestionCoordinator
        
        super.init()
        
        userSuggestionCoordinator.delegate = self
    }
    
    func processTextMessage(_ textMessage: String) {
        return self.userSuggestionCoordinator.processTextMessage(textMessage)
    }
    
    func toPresentable() -> UIViewController? {
        return self.userSuggestionCoordinator.toPresentable()
    }
}

extension UserSuggestionCoordinatorBridge: UserSuggestionCoordinatorDelegate {
    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didRequestMentionForMember member: MXRoomMember, textTrigger: String?) {
        delegate?.userSuggestionCoordinatorBridge(self, didRequestMentionForMember: member, textTrigger: textTrigger)
    }

    func userSuggestionCoordinator(_ coordinator: UserSuggestionCoordinator, didUpdateViewHeight height: CGFloat) {
        delegate?.userSuggestionCoordinatorBridge(self, didUpdateViewHeight: height)
    }
}
