// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

/// Used for storing and resolving dependencies at runtime.
struct DependencyContainer {
    
    // Stores the dependencies with type information removed.
    private var dependencyStore: [String: Any] = [:]
    
    /// Resolve a dependency by type.
    ///
    /// Given a particular `Type` (Inferred from return type),
    /// generate a key and retrieve from storage.
    /// 
    /// - Returns: The resolved dependency.
    func resolve<T>() -> T {
        let key = String(describing: T.self)
        guard let t = dependencyStore[key] as? T else {
            fatalError("No provider registered for type \(T.self)")
        }
        return t
    }
    
    /// Register a dependency.
    ///
    /// Given a dependency, generate a key from it's `Type` and save in storage.
    /// - Parameter dependency: The dependency to register.
    mutating func register<T>(dependency: T) {
        let key = String(describing: T.self)
        dependencyStore[key] = dependency
    }
}
