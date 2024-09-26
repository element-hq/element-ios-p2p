// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest
import Combine

@testable import RiotSwiftUI

class UserSessionsOverviewViewModelTests: XCTestCase {
    
    var service: MockUserSessionsOverviewService!
    var viewModel: UserSessionsOverviewViewModelProtocol!
    var context: UserSessionsOverviewViewModelType.Context!
    
    override func setUpWithError() throws {
        service = MockUserSessionsOverviewService()
        viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service)
        context = viewModel.context
    }
}
