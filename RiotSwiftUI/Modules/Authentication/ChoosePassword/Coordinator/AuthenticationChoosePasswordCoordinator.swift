//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import CommonKit

struct AuthenticationChoosePasswordCoordinatorParameters {
    let loginWizard: LoginWizard
}

enum AuthenticationChoosePasswordCoordinatorResult {
    /// Show the display name and/or avatar screens for the user to personalize their profile.
    case success
    /// Continue the flow by skipping the display name and avatar screens.
    case cancel
}

final class AuthenticationChoosePasswordCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationChoosePasswordCoordinatorParameters
    private let authenticationChoosePasswordHostingController: VectorHostingController
    private var authenticationChoosePasswordViewModel: AuthenticationChoosePasswordViewModelProtocol
    
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    /// The wizard used to handle the registration flow.
    private var loginWizard: LoginWizard { parameters.loginWizard }
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (AuthenticationChoosePasswordCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationChoosePasswordCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = AuthenticationChoosePasswordViewModel()
        let view = AuthenticationChoosePasswordScreen(viewModel: viewModel.context)
        authenticationChoosePasswordViewModel = viewModel
        authenticationChoosePasswordHostingController = VectorHostingController(rootView: view)
        authenticationChoosePasswordHostingController.vc_removeBackTitle()
        authenticationChoosePasswordHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationChoosePasswordHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[AuthenticationChoosePasswordCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationChoosePasswordHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationChoosePasswordViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationChoosePasswordCoordinator] AuthenticationChoosePasswordViewModel did complete with result: \(result).")
            
            switch result {
            case .submit(let password, let signoutAllDevices):
                self.submitPassword(password, signoutAllDevices: signoutAllDevices)
            case .cancel:
                self.callback?(.cancel)
            }
        }
    }
    
    /// Show an activity indicator whilst loading.
    @MainActor private func startLoading() {
        loadingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        loadingIndicator = nil
    }
    
    /// Submits a reset password request with signing out of all devices option
    @MainActor private func submitPassword(_ password: String, signoutAllDevices: Bool) {
        startLoading()

        currentTask = Task { [weak self] in
            do {
                try await loginWizard.resetPasswordMailConfirmed(newPassword: password,
                                                                 signoutAllDevices: signoutAllDevices)

                // Shouldn't be reachable but just in case, continue the flow.

                guard !Task.isCancelled else { return }

                self?.stopLoading()
                self?.callback?(.success)
            } catch is CancellationError {
                return
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }

    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            if mxError.errcode == kMXErrCodeStringUnauthorized {
                authenticationChoosePasswordViewModel.displayError(.emailNotVerified)
            } else {
                authenticationChoosePasswordViewModel.displayError(.mxError(mxError.error))
            }
            
            return
        }
        
        // TODO: Handle another other error types as needed.
        
        authenticationChoosePasswordViewModel.displayError(.unknown)
    }
}
