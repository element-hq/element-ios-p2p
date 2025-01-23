// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
import Combine

@testable import RiotSwiftUI

class LiveLocationSharingViewerViewModelTests: XCTestCase {
    
    var service: MockLiveLocationSharingViewerService!
    var viewModel: LiveLocationSharingViewerViewModelProtocol!
    var context: LiveLocationSharingViewerViewModelType.Context!
    var cancellables = Set<AnyCancellable>()
    
    override func setUpWithError() throws {
        service = MockLiveLocationSharingViewerService()
        viewModel = LiveLocationSharingViewerViewModel(mapStyleURL: BuildSettings.defaultTileServerMapStyleURL, service: service)
        context = viewModel.context
    }
}
