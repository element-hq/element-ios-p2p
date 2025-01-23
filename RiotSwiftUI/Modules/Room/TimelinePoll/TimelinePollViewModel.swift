//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Combine

typealias TimelinePollViewModelType = StateStoreViewModel<TimelinePollViewState,
                                                          Never,
                                                          TimelinePollViewAction>
class TimelinePollViewModel: TimelinePollViewModelType, TimelinePollViewModelProtocol {
    
    // MARK: - Properties

    // MARK: Private
    
    // MARK: Public
    
    var completion: TimelinePollViewModelCallback?
    
    // MARK: - Setup
    
    init(timelinePollDetails: TimelinePollDetails) {
        super.init(initialViewState: TimelinePollViewState(poll: timelinePollDetails, bindings: TimelinePollViewStateBindings()))
    }
    
    // MARK: - Public
    
    override func process(viewAction: TimelinePollViewAction) {
        switch viewAction {
        
        // Update local state. An update will be pushed from the coordinator once sent.
        case .selectAnswerOptionWithIdentifier(let identifier):
            guard !state.poll.closed else {
                return
            }
            
            if (state.poll.maxAllowedSelections == 1) {
                updateSingleSelectPollLocalState(selectedAnswerIdentifier: identifier, callback: completion)
            } else {
                updateMultiSelectPollLocalState(&state, selectedAnswerIdentifier: identifier, callback: completion)
            }
        }
    }
    
    // MARK: - TimelinePollViewModelProtocol
    
    func updateWithPollDetails(_ pollDetails: TimelinePollDetails) {
        state.poll = pollDetails
    }
    
    func showAnsweringFailure() {
        state.bindings.alertInfo = AlertInfo(id: .failedSubmittingAnswer,
                                             title: VectorL10n.pollTimelineVoteNotRegisteredTitle,
                                             message: VectorL10n.pollTimelineVoteNotRegisteredSubtitle)
    }
    
    func showClosingFailure() {
        state.bindings.alertInfo = AlertInfo(id: .failedClosingPoll,
                                             title: VectorL10n.pollTimelineNotClosedTitle,
                                             message: VectorL10n.pollTimelineNotClosedSubtitle)
    }
        
    // MARK: - Private
    
    func updateSingleSelectPollLocalState(selectedAnswerIdentifier: String, callback: TimelinePollViewModelCallback?) {
        state.poll.answerOptions.updateEach { answerOption in
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count = UInt(max(0, Int(answerOption.count) - 1))
                state.poll.totalAnswerCount = UInt(max(0, Int(state.poll.totalAnswerCount) - 1))
            }
            
            if answerOption.id == selectedAnswerIdentifier {
                answerOption.selected = true
                answerOption.count += 1
                state.poll.totalAnswerCount += 1
            }
        }
        
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    func updateMultiSelectPollLocalState(_ state: inout TimelinePollViewState, selectedAnswerIdentifier: String, callback: TimelinePollViewModelCallback?) {
        let selectedAnswerOptions = state.poll.answerOptions.filter { $0.selected == true }
        
        let isDeselecting = selectedAnswerOptions.filter { $0.id == selectedAnswerIdentifier }.count > 0
        
        if !isDeselecting && selectedAnswerOptions.count >= state.poll.maxAllowedSelections {
            return
        }
        
        state.poll.answerOptions.updateEach { answerOption in
            if (answerOption.id != selectedAnswerIdentifier) {
                return
            }
            
            if answerOption.selected {
                answerOption.selected = false
                answerOption.count = UInt(max(0, Int(answerOption.count) - 1))
                state.poll.totalAnswerCount = UInt(max(0, Int(state.poll.totalAnswerCount) - 1))
            } else {
                answerOption.selected = true
                answerOption.count += 1
                state.poll.totalAnswerCount += 1
            }
        }
        
        informCoordinatorOfSelectionUpdate(state: state, callback: callback)
    }
    
    func informCoordinatorOfSelectionUpdate(state: TimelinePollViewState, callback: TimelinePollViewModelCallback?) {
        let selectedIdentifiers = state.poll.answerOptions.compactMap { answerOption in
            answerOption.selected ? answerOption.id : nil
        }
        
        callback?(.selectedAnswerOptionsWithIdentifiers(selectedIdentifiers))
    }
}
