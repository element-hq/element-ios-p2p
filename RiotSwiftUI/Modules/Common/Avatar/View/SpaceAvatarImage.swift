//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import DesignKit

struct SpaceAvatarImage: View {
    
    @Environment(\.theme) var theme: ThemeSwiftUI
    @Environment(\.dependencies) var dependencies: DependencyContainer
    @StateObject var viewModel = AvatarViewModel()
    
    var mxContentUri: String?
    var matrixItemId: String
    var displayName: String?
    var size: AvatarSize
    
    var body: some View {
        Group {
            switch viewModel.viewState {
            case .empty:
                ProgressView()
            case .placeholder(let firstCharacter, let colorIndex):
                Text(String(firstCharacter))
                    .padding(10)
                    .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                    .foregroundColor(.white)
                    .background(theme.colors.namesAndAvatars[colorIndex])
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    // Make the text resizable (i.e. Make it large and then allow it to scale down)
                    .font(.system(size: 200))
                    .minimumScaleFactor(0.001)
            case .avatar(let image):
                Image(uiImage: image)
                    .resizable()
                    .frame(width: CGFloat(size.rawValue), height: CGFloat(size.rawValue))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .onChange(of: displayName, perform: { value in
            viewModel.loadAvatar(
                mxContentUri: mxContentUri,
                matrixItemId: matrixItemId,
                displayName: value,
                colorCount: theme.colors.namesAndAvatars.count,
                avatarSize: size
            )
        })
        .onAppear {
            viewModel.inject(dependencies: dependencies)
            viewModel.loadAvatar(
                mxContentUri: mxContentUri,
                matrixItemId: matrixItemId,
                displayName: displayName,
                colorCount: theme.colors.namesAndAvatars.count,
                avatarSize: size
            )
        }
    }
}

extension SpaceAvatarImage {
    init(avatarData: AvatarInputProtocol, size: AvatarSize) {
        self.init(
            mxContentUri: avatarData.mxContentUri,
            matrixItemId: avatarData.matrixItemId,
            displayName: avatarData.displayName,
            size: size
        )
    }
}

struct LiveAvatarImage_Previews: PreviewProvider {
    static let mxContentUri = "fakeUri"
    static let name = "Alice"
    static var previews: some View {
        Group {
            HStack {
                VStack(alignment: .center, spacing: 20) {
                    SpaceAvatarImage(avatarData: MockAvatarInput.example, size: .xSmall)
                    SpaceAvatarImage(avatarData: MockAvatarInput.example, size: .medium)
                    SpaceAvatarImage(avatarData: MockAvatarInput.example, size: .xLarge)
                }
                VStack(alignment: .center, spacing: 20) {
                    SpaceAvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .xSmall)
                    SpaceAvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .medium)
                    SpaceAvatarImage(mxContentUri: nil, matrixItemId: name, displayName: name, size: .xLarge)
                }
            }
            .addDependency(MockAvatarService.example)
        }
    }
}
