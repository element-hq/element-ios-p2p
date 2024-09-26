// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine

class TemplateRoomListService: TemplateRoomListServiceProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let session: MXSession
    private var listenerReference: Any?
    
    // MARK: Public
    private(set) var roomsSubject: CurrentValueSubject<[TemplateRoomListRoom], Never>
    
    // MARK: - Setup
    
    init(session: MXSession) {
        self.session = session
        
        let unencryptedRooms = session.rooms
            .filter({ !$0.summary.isEncrypted })
            .map(TemplateRoomListRoom.init(mxRoom:))
        self.roomsSubject = CurrentValueSubject(unencryptedRooms)
    }

}

fileprivate extension TemplateRoomListRoom {
    
    init(mxRoom: MXRoom) {
        self.init(id: mxRoom.roomId, avatar: mxRoom.avatarData, displayName: mxRoom.summary.displayname)
    }
}
