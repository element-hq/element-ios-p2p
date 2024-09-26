// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest
import RiotSwiftUI

class UserSuggestionUITests: MockScreenTestCase {
    func testUserSuggestionScreen() throws {
        app.goToScreenWithIdentifier(MockUserSuggestionScreenState.multipleResults.title)
        
        XCTAssert(app.tables.firstMatch.waitForExistence(timeout: 1))
        
        let firstButton = app.tables.firstMatch.buttons.firstMatch
        _ = firstButton.waitForExistence(timeout: 10)
        XCTAssert(firstButton.identifier == "displayNameText-userIdText")
    }
}
