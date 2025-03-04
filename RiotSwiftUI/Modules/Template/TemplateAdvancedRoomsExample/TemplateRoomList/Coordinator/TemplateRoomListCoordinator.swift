//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TemplateRoomListCoordinatorParameters {
    let session: MXSession
}

final class TemplateRoomListCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: TemplateRoomListCoordinatorParameters
    private let templateRoomListHostingController: UIViewController
    private var templateRoomListViewModel: TemplateRoomListViewModelProtocol
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: ((TemplateRoomListCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: TemplateRoomListCoordinatorParameters) {
        self.parameters = parameters
        let viewModel = TemplateRoomListViewModel(templateRoomListService: TemplateRoomListService(session: parameters.session))
        let view = TemplateRoomList(viewModel: viewModel.context)
            .addDependency(AvatarService.instantiate(mediaManager: parameters.session.mediaManager))
        templateRoomListViewModel = viewModel
        templateRoomListHostingController = VectorHostingController(rootView: view)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[TemplateRoomListCoordinator] did start.")
        templateRoomListViewModel.callback = { [weak self] result in
            guard let self = self else { return }
            MXLog.debug("[TemplateRoomListCoordinator] TemplateRoomListViewModel did complete with result \(result).")
            switch result {
            case .didSelectRoom(let roomId):
                self.callback?(.didSelectRoom(roomId))
            case .done:
                self.callback?(.done)
            break
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        return self.templateRoomListHostingController
    }
}
