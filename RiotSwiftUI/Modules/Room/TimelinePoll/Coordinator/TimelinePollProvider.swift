// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class TimelinePollProvider {
    static let shared = TimelinePollProvider()
    
    var session: MXSession?
    var coordinatorsForEventIdentifiers = [String: TimelinePollCoordinator]()
    
    private init() {
        
    }
    
    /// Create or retrieve the poll timeline coordinator for this event and return
    /// a view to be displayed in the timeline
    func buildTimelinePollViewForEvent(_ event: MXEvent) -> UIView? {
        guard let session = session, let room = session.room(withRoomId: event.roomId) else {
            return nil
        }
        
        if let coordinator = coordinatorsForEventIdentifiers[event.eventId] {
            return coordinator.toPresentable().view
        }
        
        let parameters = TimelinePollCoordinatorParameters(session: session, room: room, pollStartEvent: event)
        guard let coordinator = try? TimelinePollCoordinator(parameters: parameters) else {
            return nil
        }
        
        coordinatorsForEventIdentifiers[event.eventId] = coordinator
        
        return coordinator.toPresentable().view
    }
    
    /// Retrieve the poll timeline coordinator for the given event or nil if it hasn't been created yet
    func timelinePollCoordinatorForEventIdentifier(_ eventIdentifier: String) -> TimelinePollCoordinator? {
        return coordinatorsForEventIdentifiers[eventIdentifier]
    }
}
