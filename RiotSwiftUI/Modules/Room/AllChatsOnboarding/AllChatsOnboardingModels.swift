// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

// MARK: - Coordinator

// MARK: View model

enum AllChatsOnboardingViewModelResult {
    case cancel
}

// MARK: View

struct AllChatsOnboardingPageData: Identifiable {
    let id = UUID().uuidString
    let image: UIImage
    let title: String
    let message: String
}

struct AllChatsOnboardingViewState: BindableState {
    let pages: [AllChatsOnboardingPageData]
}

enum AllChatsOnboardingViewAction {
    case cancel
}
