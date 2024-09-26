// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI
import CoreLocation

enum MockLocationSharingScreenState: MockScreenState, CaseIterable {
    case shareUserLocation
    
    var screenType: Any.Type {
        LocationSharingView.self
    }
    
    var screenView: ([Any], AnyView)  {
        
        let locationSharingService = MockLocationSharingService()
        
        let mapStyleURL = URL(string: "https://api.maptiler.com/maps/streets/style.json?key=fU3vlMsMn4Jb6dnEIFsx")!
        let viewModel = LocationSharingViewModel(mapStyleURL: mapStyleURL,
                                                 avatarData: AvatarInput(mxContentUri: "", matrixItemId: "alice:matrix.org", displayName: "Alice"),
                                                 isLiveLocationSharingEnabled: true, service: locationSharingService)
        return ([viewModel],
                AnyView(LocationSharingView(context: viewModel.context)
                            .addDependency(MockAvatarService.example)))
    }
}
