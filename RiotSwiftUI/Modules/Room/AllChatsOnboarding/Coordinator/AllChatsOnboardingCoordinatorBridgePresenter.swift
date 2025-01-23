//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@objc protocol AllChatsOnboardingCoordinatorBridgePresenterDelegate {
    func allChatsOnboardingCoordinatorBridgePresenterDidCancel(_ coordinatorBridgePresenter: AllChatsOnboardingCoordinatorBridgePresenter)
}

/// `AllChatsOnboardingCoordinatorBridgePresenter` enables to start `AllChatsOnboardingCoordinator` from a view controller.
/// This bridge is used while waiting for global usage of coordinator pattern.
/// It breaks the Coordinator abstraction and it has been introduced for Objective-C compatibility (mainly for integration in legacy view controllers).
/// Each bridge should be removed once the underlying Coordinator has been integrated by another Coordinator.
@objcMembers
final class AllChatsOnboardingCoordinatorBridgePresenter: NSObject {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private var coordinator: AllChatsOnboardingCoordinator?
    
    // MARK: Public
    
    var completion: (() -> Void)?
    
    // MARK: - Public
    
    func present(from viewController: UIViewController, animated: Bool) {
        let coordinator = AllChatsOnboardingCoordinator()
        coordinator.completion = { [weak self] in
            guard let self = self else { return }
            self.completion?()
        }
        let presentable = coordinator.toPresentable()
        viewController.present(presentable, animated: animated, completion: nil)
        coordinator.start()
        
        self.coordinator = coordinator
    }
    
    func dismiss(animated: Bool, completion: (() -> Void)?) {
        guard let coordinator = self.coordinator else {
            return
        }
        coordinator.toPresentable().dismiss(animated: animated) {
            self.coordinator = nil
            completion?()
        }
    }
}

