// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import Combine
import DesignKit

/// Simple ViewModel that supports loading an avatar image
class AvatarViewModel: InjectableObject, ObservableObject {
    
    @Inject var avatarService: AvatarServiceProtocol
    
    @Published private(set) var viewState = AvatarViewState.empty
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Load an avatar
    /// - Parameters:
    ///   - mxContentUri: The matrix content URI of the avatar.
    ///   - matrixItemId: The id of the matrix item represented by the avatar.
    ///   - displayName: Display name of the avatar.
    ///   - colorCount: The count of total avatar colors used to generate the stable color index.
    ///   - avatarSize: The size of the avatar to fetch (as defined within DesignKit).
    func loadAvatar(
        mxContentUri: String?,
        matrixItemId: String,
        displayName: String?,
        colorCount: Int,
        avatarSize: AvatarSize) {
        
        let placeholderViewModel = PlaceholderAvatarViewModel(displayName: displayName,
                                                              matrixItemId: matrixItemId,
                                                              colorCount: colorCount)
        
        self.viewState = .placeholder(placeholderViewModel.firstCharacterCapitalized, placeholderViewModel.stableColorIndex)
        
        guard let mxContentUri = mxContentUri, mxContentUri.count > 0 else {
            return
        }
        
            avatarService.avatarImage(mxContentUri: mxContentUri, avatarSize: avatarSize)
            .sink { completion in
                guard case let .failure(error) = completion else { return }
                UILog.error("[AvatarService] Failed to retrieve avatar", context: error)
            } receiveValue: { image in
                self.viewState = .avatar(image)
            }
            .store(in: &cancellables)
    }
}
