//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import CommonKit

/// All Chats onboarding screen
final class AllChatsOnboardingCoordinator: NSObject, Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let hostingController: UIViewController
    private var viewModel: AllChatsOnboardingViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    override init() {
        let viewModel = AllChatsOnboardingViewModel.makeAllChatsOnboardingViewModel()
        let view = AllChatsOnboarding(viewModel: viewModel.context)
        self.viewModel = viewModel
        self.hostingController = VectorHostingController(rootView: view)
        self.indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingController)
        
        super.init()
        
        hostingController.presentationController?.delegate = self
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AllChatsOnboardingCoordinator] did start.")
        viewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AllChatsOnboardingCoordinator] AllChatsOnboardingViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.hostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = VectorL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate

extension AllChatsOnboardingCoordinator: UIAdaptivePresentationControllerDelegate {
    
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        completion?()
    }
    
}
