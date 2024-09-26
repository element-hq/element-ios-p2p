// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

extension RoomInputToolbarView {
    open override func sendCurrentMessage() {
        // Triggers auto-correct if needed.
        if self.isFirstResponder {
            let temp = UITextField(frame: .zero)
            temp.isHidden = true
            self.addSubview(temp)
            temp.becomeFirstResponder()
            self.becomeFirstResponder()
            temp.removeFromSuperview()
        }

        // Send message if any.
        if let messageToSend = self.attributedTextMessage, messageToSend.length > 0 {
            self.delegate.roomInputToolbarView(self, sendAttributedTextMessage: messageToSend)
        }

        // Reset message, disable view animation during the update to prevent placeholder distorsion.
        UIView.setAnimationsEnabled(false)
        self.attributedTextMessage = nil
        UIView.setAnimationsEnabled(true)
    }
}
