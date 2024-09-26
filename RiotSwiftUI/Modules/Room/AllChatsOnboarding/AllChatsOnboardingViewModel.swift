//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import Combine

typealias AllChatsOnboardingViewModelType = StateStoreViewModel<AllChatsOnboardingViewState,
                                                                 Never,
                                                                 AllChatsOnboardingViewAction>

class AllChatsOnboardingViewModel: AllChatsOnboardingViewModelType, AllChatsOnboardingViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    // MARK: Public

    var completion: ((AllChatsOnboardingViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeAllChatsOnboardingViewModel() -> AllChatsOnboardingViewModelProtocol {
        return AllChatsOnboardingViewModel()
    }

    private init() {
        super.init(initialViewState: Self.defaultState())
    }

    private static func defaultState() -> AllChatsOnboardingViewState {
        return AllChatsOnboardingViewState(pages: [
            AllChatsOnboardingPageData(image: Asset.Images.allChatsOnboarding1.image,
                                       title: VectorL10n.allChatsOnboardingPageTitle1,
                                       message: VectorL10n.allChatsOnboardingPageMessage1),
            AllChatsOnboardingPageData(image: Asset.Images.allChatsOnboarding2.image,
                                       title: VectorL10n.allChatsOnboardingPageTitle2,
                                       message: VectorL10n.allChatsOnboardingPageMessage2),
            AllChatsOnboardingPageData(image: Asset.Images.allChatsOnboarding3.image,
                                       title: VectorL10n.allChatsOnboardingPageTitle3,
                                       message: VectorL10n.allChatsOnboardingPageMessage3)
        ])
    }
    
    // MARK: - Public

    override func process(viewAction: AllChatsOnboardingViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        }
    }
}
