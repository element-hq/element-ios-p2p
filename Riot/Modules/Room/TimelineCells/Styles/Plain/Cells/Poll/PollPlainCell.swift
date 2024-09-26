// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

class PollPlainCell: SizableBaseRoomCell, RoomCellReactionsDisplayable, RoomCellReadMarkerDisplayable {
    
    private var pollView: UIView?
    private var event: MXEvent?
    
    override func render(_ cellData: MXKCellData!) {
        super.render(cellData)
        
        guard let contentView = roomCellContentView?.innerContentView,
              let bubbleData = cellData as? RoomBubbleCellData,
              let event = bubbleData.events.last,
              event.eventType == __MXEventType.pollStart,
              let view = TimelinePollProvider.shared.buildTimelinePollViewForEvent(event) else {
            return
        }
        
        self.event = event
        self.addPollView(view, on: contentView)
    }
    
    override func setupViews() {
        super.setupViews()
        
        roomCellContentView?.backgroundColor = .clear
        roomCellContentView?.showSenderInfo = true
        roomCellContentView?.showPaginationTitle = false
    }
    
    // The normal flow for tapping on cell content views doesn't work for bubbles without attributed strings
    override func onContentViewTap(_ sender: UITapGestureRecognizer) {
        guard let event = self.event else {
            return
        }
        
        delegate.cell(self, didRecognizeAction: kMXKRoomBubbleCellTapOnContentView, userInfo: [kMXKRoomBubbleCellEventKey: event])
    }
    
    func addPollView(_ pollView: UIView, on contentView: UIView) {
        
        self.pollView?.removeFromSuperview()
        contentView.vc_addSubViewMatchingParent(pollView)
        self.pollView = pollView
    }
}

extension PollPlainCell: RoomCellThreadSummaryDisplayable {}
