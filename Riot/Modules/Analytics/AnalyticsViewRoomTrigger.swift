// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AnalyticsEvents

@objc enum AnalyticsViewRoomTrigger: Int {
    case unknown
    case created
    case messageSearch
    case messageUser
    case notification
    case predecessor
    case roomDirectory
    case roomList
    case spaceHierarchy
    case timeline
    case tombstone
    case verificationRequest
    case widget
    case roomMemberDetail
    case fileSearch
    case roomSearch
    case searchContactDetail
    case spaceMemberDetail
    case inCall
    case spaceMenu
    case spaceSettings
    case roomPreview
    case permalink
    case linkShare
    case exploreRooms
    case spaceMembers
    case spaceBottomSheet

    var trigger: AnalyticsEvent.ViewRoom.Trigger? {
        switch self {
        case .unknown:
            return nil
        case .created:
            return .Created
        case .messageSearch:
            return .MessageSearch
        case .messageUser:
            return .MessageUser
        case .notification:
            return .Notification
        case .predecessor:
            return .Predecessor
        case .roomDirectory:
            return .RoomDirectory
        case .roomList:
            return .RoomList
        case .spaceHierarchy:
            return .SpaceHierarchy
        case .timeline:
            return .Timeline
        case .tombstone:
            return .Tombstone
        case .verificationRequest:
            return .VerificationRequest
        case .widget:
            return .Widget
        case .fileSearch:
            return .SpaceHierarchy
            //return .MobileFileSearch
        case .roomSearch:
            return .SpaceHierarchy
            //return .MobileRoomSearch
        case .roomMemberDetail:
            return .SpaceHierarchy
            //return .MobileRoomMemberDetail
        case .searchContactDetail:
            return .SpaceHierarchy
            //return .MobileSearchContactDetail
        case .spaceMemberDetail:
            return .SpaceHierarchy
            //return .MobileSpaceMemberDetail
        case .inCall:
            return .SpaceHierarchy
            //return .MobileInCall
        case .spaceMenu:
            return .SpaceHierarchy
            //return .MobileSpaceMenu
        case .spaceSettings:
            return .SpaceHierarchy
            //return .MobileSpaceSettings
        case .roomPreview:
            return .SpaceHierarchy
            //return .MobileRoomPreview
        case .permalink:
            return .SpaceHierarchy
            //return .MobilePermalink
        case .linkShare:
            return .SpaceHierarchy
            //return .MobileLinkShare
        case .exploreRooms:
            return .SpaceHierarchy
            //return .MobileExploreRooms
        case .spaceMembers:
            return .SpaceHierarchy
            //return .MobileSpaceMembers
        case .spaceBottomSheet:
            return .SpaceHierarchy
            //return .MobileSpaceBottomSheet
        }
    }
}
