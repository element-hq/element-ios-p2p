// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct UserSuggestionListWithInputViewModel {
    let listViewModel: UserSuggestionViewModel
    let callback: (String)->()
}

struct UserSuggestionListWithInput: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    // MARK: Public
    
    var viewModel: UserSuggestionListWithInputViewModel
    @State private var inputText: String = ""
    
    var body: some View {
        VStack(spacing: 0.0) {
            UserSuggestionList(viewModel: viewModel.listViewModel.context)
            TextField("Search for user", text: $inputText)
                .background(Color.white)
                .onChange(of: inputText, perform:viewModel.callback)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding([.leading, .trailing])
                .onAppear {
                    inputText = "@-" // Make the list show all available mock results
                }
        }
    }
}

// MARK: - Previews

struct UserSuggestionListWithInput_Previews: PreviewProvider {
    static let stateRenderer = MockUserSuggestionScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
