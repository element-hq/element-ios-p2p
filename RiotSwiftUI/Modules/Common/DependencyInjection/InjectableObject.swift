// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Class that can be extended that supports injection and the `@Inject` property wrapper.
open class InjectableObject: Injectable {
    var dependencies: DependencyContainer!
}
