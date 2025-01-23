// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import AnalyticsEvents

/// Failure reasons as defined in https://docs.google.com/document/d/1es7cTCeJEXXfRCTRgZerAM2Wg5ZerHjvlpfTW-gsOfI.
@objc enum DecryptionFailureReason: Int {
    case unspecified
    case olmKeysNotSent
    case olmIndexError
    case unexpected
    
    var errorName: AnalyticsEvent.Error.Name {
        switch self {
        case .unspecified:
            return .OlmUnspecifiedError
        case .olmKeysNotSent:
            return .OlmKeysNotSentError
        case .olmIndexError:
            return .OlmIndexError
        case .unexpected:
            return .UnknownError
        }
    }
}

/// `DecryptionFailure` represents a decryption failure.
@objcMembers class DecryptionFailure: NSObject {
    /// The id of the event that was unabled to decrypt.
    let failedEventId: String
    /// The time the failure has been reported.
    let ts: TimeInterval = Date().timeIntervalSince1970
    /// Decryption failure reason.
    let reason: DecryptionFailureReason
    /// Additional context of failure
    let context: String
    
    init(failedEventId: String, reason: DecryptionFailureReason, context: String) {
        self.failedEventId = failedEventId
        self.reason = reason
        self.context = context
    }
}
