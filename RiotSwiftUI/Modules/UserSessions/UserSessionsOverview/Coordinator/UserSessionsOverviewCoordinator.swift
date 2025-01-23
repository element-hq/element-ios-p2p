//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import CommonKit

struct UserSessionsOverviewCoordinatorParameters {
    let session: MXSession
}

final class UserSessionsOverviewCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: UserSessionsOverviewCoordinatorParameters
    private let userSessionsOverviewHostingController: UIViewController
    private var userSessionsOverviewViewModel: UserSessionsOverviewViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: UserSessionsOverviewCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = UserSessionsOverviewViewModel(userSessionsOverviewService: UserSessionsOverviewService(mxSession: parameters.session))
        let view = UserSessionsOverview(viewModel: viewModel.context)
        userSessionsOverviewViewModel = viewModel
        
        let hostingViewController = VectorHostingController(rootView: view)
        
        userSessionsOverviewHostingController = hostingViewController
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: hostingViewController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionsOverviewCoordinator] did start.")
        userSessionsOverviewViewModel.completion = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[UserSessionsOverviewCoordinator] UserSessionsOverviewViewModel did complete with result: \(result).")
            switch result {
            case .cancel:
                self.completion?()
            case .showAllUnverifiedSessions:
                self.showAllUnverifiedSessions()
            case .showAllInactiveSessions:
                self.showAllInactiveSessions()
            case .verifyCurrentSession:
                self.startVerifyCurrentSession()
            case .showCurrentSessionDetails:
                self.showCurrentSessionDetails()
            case .showAllOtherSessions:
                self.showAllOtherSessions()
            case .showUserSessionDetails(let sessionId):
                self.showUserSessionDetails(sessionId: sessionId)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.userSessionsOverviewHostingController
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
    
    private func showAllUnverifiedSessions() {
        // TODO
    }
    
    private func showAllInactiveSessions() {
        // TODO
    }
    
    private func startVerifyCurrentSession() {
        // TODO
    }
    
    private func showCurrentSessionDetails() {
        // TODO
    }
    
    private func showUserSessionDetails(sessionId: String) {
        // TODO
    }
    
    private func showAllOtherSessions() {
        // TODO
    }
}
