// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Combine

typealias TemplateRoomListViewModelType = StateStoreViewModel<TemplateRoomListViewState,
                                                              Never,
                                                              TemplateRoomListViewAction>

class TemplateRoomListViewModel: TemplateRoomListViewModelType, TemplateRoomListViewModelProtocol {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let templateRoomListService: TemplateRoomListServiceProtocol
    
    // MARK: Public
    
    var callback: ((TemplateRoomListViewModelAction) -> Void)?
    
    // MARK: - Setup
    
    init(templateRoomListService: TemplateRoomListServiceProtocol) {
        self.templateRoomListService = templateRoomListService
        super.init(initialViewState: Self.defaultState(templateRoomListService: templateRoomListService))
        startObservingRooms()
    }
    
    private static func defaultState(templateRoomListService: TemplateRoomListServiceProtocol) -> TemplateRoomListViewState {
        return TemplateRoomListViewState(rooms: templateRoomListService.roomsSubject.value)
    }
    
    private func startObservingRooms() {
        templateRoomListService
            .roomsSubject
            .sink { [weak self] rooms in
                self?.state.rooms = rooms
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: TemplateRoomListViewAction) {
        switch viewAction {
        case .didSelectRoom(let roomId):
            didSelect(by: roomId)
        case .done:
            done()
        }
    }
    
    // MARK: - Private
    
    private func done() {
        callback?(.done)
    }
    
    private func didSelect(by roomId: String) {
        callback?(.didSelectRoom(roomId))
    }
}
