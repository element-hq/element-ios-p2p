// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine
import CoreLocation

// MARK: View model

enum StaticLocationViewingViewAction {
    case close
    case share
}

enum StaticLocationViewingViewModelResult {
    case close
    case share(_ coordinate: CLLocationCoordinate2D)
}

// MARK: View

struct StaticLocationViewingViewState: BindableState {
    
    /// Map style URL
    let mapStyleURL: URL
    
    /// Current user avatarData
    let userAvatarData: AvatarInputProtocol
    
    /// Shared annotation to display existing location
    let sharedAnnotation: LocationAnnotation
    
    var showLoadingIndicator: Bool = false
    
    var shareButtonEnabled: Bool {
        !showLoadingIndicator
    }

    let errorSubject = PassthroughSubject<LocationSharingViewError, Never>()
    
    var bindings = StaticLocationViewingViewBindings()
}

struct StaticLocationViewingViewBindings {
    var alertInfo: AlertInfo<LocationSharingAlertType>?
}
