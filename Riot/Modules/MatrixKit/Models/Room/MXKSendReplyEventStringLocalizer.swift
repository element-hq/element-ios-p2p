// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class MXKSendReplyEventStringLocalizer: NSObject, MXSendReplyEventStringLocalizerProtocol {
    func senderSentAnImage() -> String {
        return VectorL10n.messageReplyToSenderSentAnImage
    }

    func senderSentAVideo() -> String {
        return VectorL10n.messageReplyToSenderSentAVideo
    }

    func senderSentAnAudioFile() -> String {
        return VectorL10n.messageReplyToSenderSentAnAudioFile
    }

    func senderSentAVoiceMessage() -> String {
        return VectorL10n.messageReplyToSenderSentAVoiceMessage
    }

    func senderSentAFile() -> String {
        return VectorL10n.messageReplyToSenderSentAFile
    }

    func senderSentTheirLocation() -> String {
        return VectorL10n.messageReplyToSenderSentTheirLocation
    }
    
    func senderSentTheirLiveLocation() -> String {
        return VectorL10n.messageReplyToSenderSentTheirLiveLocation
    }

    func messageToReplyToPrefix() -> String {
        return VectorL10n.messageReplyToMessageToReplyToPrefix
    }
}
