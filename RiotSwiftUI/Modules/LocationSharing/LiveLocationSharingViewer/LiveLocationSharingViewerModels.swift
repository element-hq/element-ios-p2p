// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine
import CoreLocation

// MARK: - Coordinator

// MARK: View model

enum LiveLocationSharingViewerViewModelResult {    
    case done
    case share(_ coordinate: CLLocationCoordinate2D)
}

// MARK: View

struct LiveLocationSharingViewerViewState: BindableState {
    
    /// Map style URL
    let mapStyleURL: URL
    
    /// Map annotations to display on map
    var annotations: [UserLocationAnnotation]

    /// Map annotation to focus on
    var highlightedAnnotation: LocationAnnotation?
    
    /// Live location list items
    var listItemsViewData: [LiveLocationListItemViewData]

    var showLoadingIndicator: Bool = false
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }
    
    /// True to indicate that everybody stopped to share live location sharing in the room
    var isAllLocationSharingEnded: Bool {
        return listItemsViewData.isEmpty
    }
    
    var isBottomSheetVisible: Bool {
        return isAllLocationSharingEnded == false
    }
    
    var showMapLoadingError: Bool = false

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = LocationSharingViewStateBindings()
}

struct LiveLocationSharingViewerViewStateBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
    var showMapCreditsSheet = false
}

enum LiveLocationSharingViewerViewAction {
    case done
    case stopSharing
    case tapListItem(_ userId: String)
    case share(_ annotation: UserLocationAnnotation)
    case mapCreditsDidTap
}
