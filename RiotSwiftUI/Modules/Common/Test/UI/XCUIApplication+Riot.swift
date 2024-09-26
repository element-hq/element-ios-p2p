// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import XCTest

extension XCUIApplication {
    func goToScreenWithIdentifier(_ identifier: String) {
        // Search for the screen identifier
        textFields["searchQueryTextField"].tap()
        typeText(identifier)
        
        let button = self.buttons[identifier]
        let footer = staticTexts["footerText"]
        
        while !button.isHittable && !footer.isHittable {
            self.tables.firstMatch.swipeUp()
        }
        
        button.tap()
    }
}
