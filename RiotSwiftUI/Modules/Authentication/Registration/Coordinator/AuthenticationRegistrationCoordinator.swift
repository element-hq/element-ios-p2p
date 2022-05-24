//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import CommonKit
import MatrixSDK

struct AuthenticationRegistrationCoordinatorParameters {
    let navigationRouter: NavigationRouterType
    let authenticationService: AuthenticationService
    /// The registration flow that is available for the chosen server.
    let registrationFlow: RegistrationResult?
    /// The login mode to allow SSO buttons to be shown when available.
    let loginMode: LoginMode
}

enum AuthenticationRegistrationCoordinatorResult {
    /// The screen completed with the associated registration result.
    case completed(RegistrationResult)
}

final class AuthenticationRegistrationCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: AuthenticationRegistrationCoordinatorParameters
    private let authenticationRegistrationHostingController: VectorHostingController
    private var authenticationRegistrationViewModel: AuthenticationRegistrationViewModelProtocol
    
    private var currentTask: Task<Void, Error>? {
        willSet {
            currentTask?.cancel()
        }
    }
    
    private var navigationRouter: NavigationRouterType { parameters.navigationRouter }
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var waitingIndicator: UserIndicator?
    
    /// The authentication service used for the registration.
    private var authenticationService: AuthenticationService { parameters.authenticationService }
    /// The wizard used to handle the registration flow. May be `nil` when only SSO is supported.
    private var registrationWizard: RegistrationWizard? { parameters.authenticationService.registrationWizard }
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    @MainActor var callback: ((AuthenticationRegistrationCoordinatorResult) -> Void)?
    
    // MARK: - Setup
    
    @MainActor init(parameters: AuthenticationRegistrationCoordinatorParameters) {
        self.parameters = parameters
        
        let homeserver = parameters.authenticationService.state.homeserver
        let viewModel = AuthenticationRegistrationViewModel(homeserver: homeserver.viewData)
        authenticationRegistrationViewModel = viewModel
        
        let view = AuthenticationRegistrationScreen(viewModel: viewModel.context)
        authenticationRegistrationHostingController = VectorHostingController(rootView: view)
        authenticationRegistrationHostingController.vc_removeBackTitle()
        authenticationRegistrationHostingController.enableNavigationBarScrollEdgeAppearance = true
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: authenticationRegistrationHostingController)
    }
    
    // MARK: - Public
    func start() {
        MXLog.debug("[AuthenticationRegistrationCoordinator] did start.")
        Task { await setupViewModel() }
    }
    
    func toPresentable() -> UIViewController {
        return self.authenticationRegistrationHostingController
    }
    
    // MARK: - Private
    
    /// Set up the view model. This method is extracted from `start()` so it can run on the `MainActor`.
    @MainActor private func setupViewModel() {
        authenticationRegistrationViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[AuthenticationRegistrationCoordinator] AuthenticationRegistrationViewModel did complete with result: \(result).")
            switch result {
            case .selectServer:
                self.presentServerSelectionScreen()
            case.validateUsername(let username):
                self.validateUsername(username)
            case .createAccount(let username, let password):
                self.createAccount(username: username, password: password)
            }
        }
    }
    
    /// Show a blocking activity indicator whilst saving.
    @MainActor private func startLoading() {
        waitingIndicator = indicatorPresenter.present(.loading(label: VectorL10n.loading, isInteractionBlocking: true))
    }
    
    /// Hide the currently displayed activity indicator.
    @MainActor private func stopLoading() {
        waitingIndicator = nil
    }
    
    /// Asks the homeserver to check the supplied username's format and availability.
    @MainActor private func validateUsername(_ username: String) {
        guard let registrationWizard = registrationWizard else {
            MXLog.failure("[AuthenticationRegistrationCoordinator] The registration wizard was requested before getting the login flow.")
            return
        }
        
        currentTask = Task {
            do {
                _ = try await registrationWizard.registrationAvailable(username: username)
            } catch {
                guard !Task.isCancelled, let mxError = MXError(nsError: error as NSError) else { return }
                if mxError.errcode == kMXErrCodeStringUserInUse
                    || mxError.errcode == kMXErrCodeStringInvalidUsername
                    || mxError.errcode == kMXErrCodeStringExclusiveResource {
                    authenticationRegistrationViewModel.displayError(.usernameUnavailable(mxError.error))
                }
            }
        }
    }
    
    /// Creates an account on the homeserver with the supplied username and password.
    @MainActor private func createAccount(username: String, password: String) {
        guard let registrationWizard = registrationWizard else {
            MXLog.failure("[AuthenticationRegistrationCoordinator] createAccount: The registration wizard is nil.")
            return
        }
        
        startLoading()
        
        currentTask = Task { [weak self] in
            do {
                let result = try await registrationWizard.createAccount(username: username,
                                                                        password: password,
                                                                        initialDeviceDisplayName: UIDevice.current.initialDisplayName)
                
                guard !Task.isCancelled else { return }
                callback?(.completed(result))
                
                self?.stopLoading()
            } catch {
                self?.stopLoading()
                self?.handleError(error)
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    @MainActor private func handleError(_ error: Error) {
        if let mxError = MXError(nsError: error as NSError) {
            authenticationRegistrationViewModel.displayError(.mxError(mxError.error))
            return
        }
        
        if let authenticationError = error as? AuthenticationError {
            switch authenticationError {
            case .invalidHomeserver:
                authenticationRegistrationViewModel.displayError(.invalidHomeserver)
            case .loginFlowNotCalled:
                #warning("Reset the flow")
            case .missingMXRestClient:
                #warning("Forget the soft logout session")
            }
            return
        }
        
        if let registrationError = error as? RegistrationError {
            switch registrationError {
            case .registrationDisabled:
                authenticationRegistrationViewModel.displayError(.registrationDisabled)
            case .createAccountNotCalled, .missingThreePIDData, .missingThreePIDURL, .threePIDClientFailure, .threePIDValidationFailure, .waitingForThreePIDValidation:
                // Shouldn't happen at this stage
                authenticationRegistrationViewModel.displayError(.unknown)
            }
            return
        }
        
        authenticationRegistrationViewModel.displayError(.unknown)
    }
    
    /// Presents the server selection screen as a modal.
    @MainActor private func presentServerSelectionScreen() {
        MXLog.debug("[AuthenticationCoordinator] showServerSelectionScreen")
        let parameters = AuthenticationServerSelectionCoordinatorParameters(authenticationService: authenticationService,
                                                                            flow: .register,
                                                                            hasModalPresentation: true)
        let coordinator = AuthenticationServerSelectionCoordinator(parameters: parameters)
        coordinator.callback = { [weak self, weak coordinator] result in
            guard let self = self, let coordinator = coordinator else { return }
            self.serverSelectionCoordinator(coordinator, didCompleteWith: result)
        }
        
        coordinator.start()
        add(childCoordinator: coordinator)
        
        let modalRouter = NavigationRouter()
        modalRouter.setRootModule(coordinator)
        
        navigationRouter.present(modalRouter, animated: true)
    }
    
    /// Handles the result from the server selection modal, dismissing it after updating the view.
    @MainActor private func serverSelectionCoordinator(_ coordinator: AuthenticationServerSelectionCoordinator,
                                                       didCompleteWith result: AuthenticationServerSelectionCoordinatorResult) {
        if result == .updated {
            let homeserver = authenticationService.state.homeserver
            authenticationRegistrationViewModel.update(homeserver: homeserver.viewData)
        }
        
        navigationRouter.dismissModule(animated: true) { [weak self] in
            self?.remove(childCoordinator: coordinator)
        }
    }
}
