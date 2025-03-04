// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

class AddRoomSelectorViewProvider: MatrixItemChooserCoordinatorViewProvider {
    func view(with viewModel: MatrixItemChooserViewModelType.Context) -> AnyView {
        return AnyView(AddRoomSelector(viewModel: viewModel))
    }
}
