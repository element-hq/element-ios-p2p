// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UIKit
import MatrixSDK

/// Text attachment for pills display.
@available (iOS 15.0, *)
@objcMembers
class PillTextAttachment: NSTextAttachment {
    // MARK: - Properties
    /// Return `PillTextAttachmentData` contained in the text attachment.
    var data: PillTextAttachmentData? {
        get {
            guard let contents = contents else { return nil }
            return try? Self.serializationService.deserialize(contents)
        }
        set {
            guard let newValue = newValue else {
                contents = nil
                return
            }
            contents = try? Self.serializationService.serialize(newValue)
            updateBounds()
        }
    }
    private static let serializationService: SerializationServiceType = SerializationService()

    // MARK: - Init
    override init(data contentData: Data?, ofType uti: String?) {
        super.init(data: contentData, ofType: uti)

        updateBounds()
    }

    /// Create a Mention Pill text attachment for given room member.
    ///
    /// - Parameters:
    ///   - roomMember: the room member
    ///   - isHighlighted: whether this pill should be highlighted
    ///   - font: the text font
    convenience init?(withRoomMember roomMember: MXRoomMember,
                      isHighlighted: Bool,
                      font: UIFont) {
        let data = PillTextAttachmentData(matrixItemId: roomMember.userId,
                                          displayName: roomMember.displayname,
                                          avatarUrl: roomMember.avatarUrl,
                                          isHighlighted: isHighlighted,
                                          alpha: 1.0,
                                          font: font)

        guard let encodedData = try? Self.serializationService.serialize(data) else { return nil }
        self.init(data: encodedData, ofType: PillsFormatter.pillUTType)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        updateBounds()
    }
}

// MARK: - Private
@available (iOS 15.0, *)
private extension PillTextAttachment {
    func updateBounds() {
        guard let data = data else { return }
        let pillSize = PillAttachmentViewProvider.size(forDisplayText: data.displayText, andFont: data.font)
        // Offset to align pill centerY with text centerY.
        let offset = data.font.descender + (data.font.lineHeight - pillSize.height) / 2.0
        self.bounds = CGRect(origin: CGPoint(x: 0.0, y: offset), size: pillSize)
    }
}
