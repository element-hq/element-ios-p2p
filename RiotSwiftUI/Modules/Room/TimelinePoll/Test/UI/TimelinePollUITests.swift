//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest
import RiotSwiftUI

class TimelinePollUITests: MockScreenTestCase {
    func testOpenDisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.openDisclosed.title)
        
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["20 votes cast"].exists)
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 5 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 5 votes"].value as! String, "25%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
        
        app.buttons["First, 10 votes"].tap()
        
        XCTAssert(app.buttons["First, 11 votes"].exists)
        XCTAssertEqual(app.buttons["First, 11 votes"].value as! String, "55%")
        
        XCTAssert(app.buttons["Second, 4 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 4 votes"].value as! String, "20%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
        
        app.buttons["Third, 15 votes"].tap()
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 4 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 4 votes"].value as! String, "20%")
        
        XCTAssert(app.buttons["Third, 16 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 16 votes"].value as! String, "80%")
    }
    
    func testOpenUndisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.openUndisclosed.title)
        
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["20 votes cast"].exists)
        
        XCTAssert(!app.buttons["First, 10 votes"].exists)
        XCTAssert(app.buttons["First"].exists)
        XCTAssertTrue((app.buttons["First"].value as! String).isEmpty)
        
        XCTAssert(!app.buttons["Second, 5 votes"].exists)
        XCTAssert(app.buttons["Second"].exists)
        XCTAssertTrue((app.buttons["Second"].value as! String).isEmpty)
        
        XCTAssert(!app.buttons["Third, 15 votes"].exists)
        XCTAssert(app.buttons["Third"].exists)
        XCTAssertTrue((app.buttons["Third"].value as! String).isEmpty)
        
        app.buttons["First"].tap()
        
        XCTAssert(app.buttons["First"].exists)
        XCTAssert(app.buttons["Second"].exists)
        XCTAssert(app.buttons["Third"].exists)
                
        app.buttons["Third"].tap()
        
        XCTAssert(app.buttons["First"].exists)
        XCTAssert(app.buttons["Second"].exists)
        XCTAssert(app.buttons["Third"].exists)
    }
    
    func testClosedDisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.closedDisclosed.title)
        checkClosedPoll()
    }
    
    func testClosedUndisclosedPoll() {
        app.goToScreenWithIdentifier(MockTimelinePollScreenState.closedUndisclosed.title)
        checkClosedPoll()
    }
    
    private func checkClosedPoll() {
        XCTAssert(app.staticTexts["Question"].exists)
        XCTAssert(app.staticTexts["Final results based on 20 votes"].exists)
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 5 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 5 votes"].value as! String, "25%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
        
        app.buttons["First, 10 votes"].tap()
        
        XCTAssert(app.buttons["First, 10 votes"].exists)
        XCTAssertEqual(app.buttons["First, 10 votes"].value as! String, "50%")
        
        XCTAssert(app.buttons["Second, 5 votes"].exists)
        XCTAssertEqual(app.buttons["Second, 5 votes"].value as! String, "25%")
        
        XCTAssert(app.buttons["Third, 15 votes"].exists)
        XCTAssertEqual(app.buttons["Third, 15 votes"].value as! String, "75%")
    }
}
