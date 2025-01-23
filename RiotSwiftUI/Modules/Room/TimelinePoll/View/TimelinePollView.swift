// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct TimelinePollView: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.theme) private var theme: ThemeSwiftUI
    
    // MARK: Public
    
    @ObservedObject var viewModel: TimelinePollViewModel.Context
    
    var body: some View {
        let poll = viewModel.viewState.poll
        
        VStack(alignment: .leading, spacing: 16.0) {
            
            Text(poll.question)
                .font(theme.fonts.bodySB)
                .foregroundColor(theme.colors.primaryContent) +
                Text(editedText)
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.secondaryContent)
            
            VStack(spacing: 24.0) {
                ForEach(poll.answerOptions) { answerOption in
                    TimelinePollAnswerOptionButton(poll: poll, answerOption: answerOption) {
                        viewModel.send(viewAction: .selectAnswerOptionWithIdentifier(answerOption.id))
                    }
                }
            }
            .disabled(poll.closed)
            .fixedSize(horizontal: false, vertical: true)
            
            Text(totalVotesString)
                .font(theme.fonts.footnote)
                .foregroundColor(theme.colors.tertiaryContent)
        }
        .padding([.horizontal, .top], 2.0)
        .padding([.bottom])
        .alert(item: $viewModel.alertInfo) { info in
            info.alert
        }
    }
    
    private var totalVotesString: String {
        let poll = viewModel.viewState.poll
        
        if poll.closed {
            if poll.totalAnswerCount == 1 {
                return VectorL10n.pollTimelineTotalFinalResultsOneVote
            } else {
                return VectorL10n.pollTimelineTotalFinalResults(Int(poll.totalAnswerCount))
            }
        }
        
        switch poll.totalAnswerCount {
        case 0:
            return VectorL10n.pollTimelineTotalNoVotes
        case 1:
            return (poll.hasCurrentUserVoted || poll.type == .undisclosed ?
                        VectorL10n.pollTimelineTotalOneVote :
                        VectorL10n.pollTimelineTotalOneVoteNotVoted)
        default:
            return (poll.hasCurrentUserVoted || poll.type == .undisclosed ?
                        VectorL10n.pollTimelineTotalVotes(Int(poll.totalAnswerCount)) :
                        VectorL10n.pollTimelineTotalVotesNotVoted(Int(poll.totalAnswerCount)))
        }
    }
    
    private var editedText: String {
        viewModel.viewState.poll.hasBeenEdited ? " \(VectorL10n.eventFormatterMessageEditedMention)" : ""
    }
}

// MARK: - Previews

struct TimelinePollView_Previews: PreviewProvider {
    static let stateRenderer = MockTimelinePollScreenState.stateRenderer
    static var previews: some View {
        stateRenderer.screenGroup()
    }
}
