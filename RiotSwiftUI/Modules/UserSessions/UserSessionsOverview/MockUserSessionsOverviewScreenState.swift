// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

/// Using an enum for the screen allows you define the different state cases with
/// the relevant associated data for each case.
enum MockUserSessionsOverviewScreenState: MockScreenState, CaseIterable {
    // A case for each state you want to represent
    // with specific, minimal associated data that will allow you
    // mock that screen.
    case verifiedSession
    
    /// The associated screen
    var screenType: Any.Type {
        UserSessionsOverview.self
    }
    
    /// A list of screen state definitions
    static var allCases: [MockUserSessionsOverviewScreenState] {
        // Each of the presence statuses
        return [.verifiedSession]
    }
    
    /// Generate the view struct for the screen state.
    var screenView: ([Any], AnyView)  {
        let service: MockUserSessionsOverviewService = MockUserSessionsOverviewService()
        switch self {
        case .verifiedSession:
            break
        }
        
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: service)
        
        // can simulate service and viewModel actions here if needs be.
        
        return (
            [service, viewModel],
            AnyView(UserSessionsOverview(viewModel: viewModel.context)
                .addDependency(MockAvatarService.example))
        )
    }
}
