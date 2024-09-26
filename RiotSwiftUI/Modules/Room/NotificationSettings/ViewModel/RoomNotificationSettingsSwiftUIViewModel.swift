// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine

class RoomNotificationSettingsSwiftUIViewModel: RoomNotificationSettingsViewModel, ObservableObject {

    @Published var viewState: RoomNotificationSettingsViewState
    
    lazy var cancellables = Set<AnyCancellable>()
    
    override init(roomNotificationService: RoomNotificationSettingsServiceType, initialState: RoomNotificationSettingsViewState) {
        self.viewState = initialState
        super.init(roomNotificationService: roomNotificationService, initialState: initialState)
    }
    
    override func update(viewState: RoomNotificationSettingsViewState) {
        super.update(viewState: viewState)
        self.viewState = viewState
    }
}
