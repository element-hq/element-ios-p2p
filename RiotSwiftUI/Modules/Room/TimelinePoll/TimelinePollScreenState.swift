// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

enum MockTimelinePollScreenState: MockScreenState, CaseIterable {
    case openDisclosed
    case closedDisclosed
    case openUndisclosed
    case closedUndisclosed
    
    var screenType: Any.Type {
        TimelinePollDetails.self
    }
    
    var screenView: ([Any], AnyView)  {
        let answerOptions = [TimelinePollAnswerOption(id: "1", text: "First", count: 10, winner: false, selected: false),
                             TimelinePollAnswerOption(id: "2", text: "Second", count: 5, winner: false, selected: true),
                             TimelinePollAnswerOption(id: "3", text: "Third", count: 15, winner: true, selected: false)]
        
        let poll = TimelinePollDetails(question: "Question",
                                       answerOptions: answerOptions,
                                       closed: (self == .closedDisclosed || self == .closedUndisclosed ? true : false),
                                       totalAnswerCount: 20,
                                       type: (self == .closedDisclosed || self == .openDisclosed ? .disclosed : .undisclosed),
                                       maxAllowedSelections: 1,
                                       hasBeenEdited: false)
        
        let viewModel = TimelinePollViewModel(timelinePollDetails: poll)
        
        return ([viewModel], AnyView(TimelinePollView(viewModel: viewModel.context)))
    }
}
