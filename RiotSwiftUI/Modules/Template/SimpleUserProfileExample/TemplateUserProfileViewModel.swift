//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI
import Combine

typealias TemplateUserProfileViewModelType = StateStoreViewModel<TemplateUserProfileViewState,
                                                                 Never,
                                                                 TemplateUserProfileViewAction>

class TemplateUserProfileViewModel: TemplateUserProfileViewModelType, TemplateUserProfileViewModelProtocol {

    // MARK: - Properties

    // MARK: Private

    private let templateUserProfileService: TemplateUserProfileServiceProtocol

    // MARK: Public

    var completion: ((TemplateUserProfileViewModelResult) -> Void)?

    // MARK: - Setup

    static func makeTemplateUserProfileViewModel(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewModelProtocol {
        return TemplateUserProfileViewModel(templateUserProfileService: templateUserProfileService)
    }

    private init(templateUserProfileService: TemplateUserProfileServiceProtocol) {
        self.templateUserProfileService = templateUserProfileService
        super.init(initialViewState: Self.defaultState(templateUserProfileService: templateUserProfileService))
        setupPresenceObserving()
    }

    private static func defaultState(templateUserProfileService: TemplateUserProfileServiceProtocol) -> TemplateUserProfileViewState {
        return TemplateUserProfileViewState(
            avatar: templateUserProfileService.avatarData,
            displayName: templateUserProfileService.displayName,
            presence: templateUserProfileService.presenceSubject.value,
            count: 0
        )
    }
    
    private func setupPresenceObserving() {
        templateUserProfileService
            .presenceSubject
            .sink(receiveValue: { [weak self] presence in
                self?.state.presence = presence
            })
            .store(in: &cancellables)
    }
    
    // MARK: - Public

    override func process(viewAction: TemplateUserProfileViewAction) {
        switch viewAction {
        case .cancel:
            completion?(.cancel)
        case .done:
            completion?(.done)
        case .incrementCount:
            state.count += 1
        case .decrementCount:
            state.count -= 1
        }
    }
}
