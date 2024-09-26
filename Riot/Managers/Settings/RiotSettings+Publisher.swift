// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine

extension RiotSettings {
    
    @available(iOS 13.0, *)
    func publisher(for key: String) -> AnyPublisher<Notification, Never> {
        return NotificationCenter.default.publisher(for: .userDefaultValueUpdated)
            .filter({ $0.object as? String == key })
            .eraseToAnyPublisher()
    }
    
}
