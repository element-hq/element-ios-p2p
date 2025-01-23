// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// A protocol for classes that can be injected with a dependency container
protocol Injectable: AnyObject {
    var dependencies: DependencyContainer! { get set }
}


extension Injectable {
    
    /// Used to inject the dependency container into an Injectable.
    /// - Parameter dependencies: The `DependencyContainer` to inject.
    func inject(dependencies: DependencyContainer) {
        self.dependencies = dependencies
    }
}
