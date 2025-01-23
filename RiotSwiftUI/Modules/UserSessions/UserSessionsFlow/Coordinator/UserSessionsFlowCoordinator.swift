// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CommonKit

struct UserSessionsFlowCoordinatorParameters {
    let session: MXSession
    let router: NavigationRouterType?
}

final class UserSessionsFlowCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: UserSessionsFlowCoordinatorParameters
    private let navigationRouter: NavigationRouterType
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var completion: (() -> Void)?
    
    // MARK: - Setup
    
    init(parameters: UserSessionsFlowCoordinatorParameters) {
        self.parameters = parameters
        
        self.navigationRouter = parameters.router ?? NavigationRouter(navigationController: RiotNavigationController())
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[UserSessionsFlowCoordinator] did start.")
        
        let rootCoordinatorParameters = UserSessionsOverviewCoordinatorParameters(session: self.parameters.session)
        
        let rootCoordinator = UserSessionsOverviewCoordinator(parameters: rootCoordinatorParameters)
        
        rootCoordinator.start()

        self.add(childCoordinator: rootCoordinator)

        if self.navigationRouter.modules.isEmpty == false {
            self.navigationRouter.push(rootCoordinator, animated: true, popCompletion: { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
                self?.completion?()
            })
        } else {
            self.navigationRouter.setRootModule(rootCoordinator) { [weak self] in
                self?.remove(childCoordinator: rootCoordinator)
                self?.completion?()
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.navigationRouter.toPresentable()
    }
}
