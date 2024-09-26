// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

typealias TimelinePollViewModelCallback = ((TimelinePollViewModelResult) -> Void)

enum TimelinePollViewAction {
    case selectAnswerOptionWithIdentifier(String)
}

enum TimelinePollViewModelResult {
    case selectedAnswerOptionsWithIdentifiers([String])
}

enum TimelinePollType {
    case disclosed
    case undisclosed
}

struct TimelinePollAnswerOption: Identifiable {
    var id: String
    var text: String
    var count: UInt
    var winner: Bool
    var selected: Bool
    
    init(id: String, text: String, count: UInt, winner: Bool, selected: Bool) {
        self.id = id
        self.text = text
        self.count = count
        self.winner = winner
        self.selected = selected
    }
}

extension MutableCollection where Element == TimelinePollAnswerOption {
    mutating func updateEach(_ update: (inout Element) -> Void) {
        for index in indices {
            update(&self[index])
        }
    }
}

struct TimelinePollDetails {
    var question: String
    var answerOptions: [TimelinePollAnswerOption]
    var closed: Bool
    var totalAnswerCount: UInt
    var type: TimelinePollType
    var maxAllowedSelections: UInt
    var hasBeenEdited: Bool = true
    
    init(question: String, answerOptions: [TimelinePollAnswerOption],
         closed: Bool,
         totalAnswerCount: UInt,
         type: TimelinePollType,
         maxAllowedSelections: UInt,
         hasBeenEdited: Bool) {
        self.question = question
        self.answerOptions = answerOptions
        self.closed = closed
        self.totalAnswerCount = totalAnswerCount
        self.type = type
        self.maxAllowedSelections = maxAllowedSelections
        self.hasBeenEdited = hasBeenEdited
    }
    
    var hasCurrentUserVoted: Bool {
        answerOptions.filter { $0.selected == true}.count > 0
    }
    
    var shouldDiscloseResults: Bool {
        if closed {
            return totalAnswerCount > 0
        } else {
            return type == .disclosed && totalAnswerCount > 0 && hasCurrentUserVoted
        }
    }
}

struct TimelinePollViewState: BindableState {
    var poll: TimelinePollDetails
    var bindings: TimelinePollViewStateBindings
}

struct TimelinePollViewStateBindings {
    var alertInfo: AlertInfo<TimelinePollAlertType>?
}

enum TimelinePollAlertType {
    case failedClosingPoll
    case failedSubmittingAnswer
}
