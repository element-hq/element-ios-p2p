// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Provider for mention Pills attachment view.
@available(iOS 15.0, *)
@objc class PillAttachmentViewProvider: NSTextAttachmentViewProvider {
    // MARK: - Properties
    private static let pillAttachmentViewSizes = PillAttachmentView.Sizes(verticalMargin: 2.0,
                                                                          horizontalMargin: 4.0,
                                                                          avatarSideLength: 16.0)
    private weak var messageTextView: MXKMessageTextView?

    // MARK: - Override
    override init(textAttachment: NSTextAttachment, parentView: UIView?, textLayoutManager: NSTextLayoutManager?, location: NSTextLocation) {
        super.init(textAttachment: textAttachment, parentView: parentView, textLayoutManager: textLayoutManager, location: location)

        self.messageTextView = parentView?.superview as? MXKMessageTextView
    }

    override func loadView() {
        super.loadView()

        guard let textAttachment = self.textAttachment as? PillTextAttachment else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment is missing or not of expected class")
            return
        }

        guard let pillData = textAttachment.data else {
            MXLog.debug("[PillAttachmentViewProvider]: attachment misses pill data")
            return
        }

        let mainSession = AppDelegate.theDelegate().mxSessions.first as? MXSession

        let pillView = PillAttachmentView(frame: CGRect(origin: .zero, size: Self.size(forDisplayText: pillData.displayText,
                                                                                       andFont: pillData.font)),
                                          sizes: Self.pillAttachmentViewSizes,
                                          theme: ThemeService.shared().theme,
                                          mediaManager: mainSession?.mediaManager,
                                          andPillData: pillData)
        view = pillView
        messageTextView?.registerPillView(pillView)
    }
}

@available(iOS 15.0, *)
extension PillAttachmentViewProvider {
    /// Computes size required to display a pill for given display text.
    ///
    /// - Parameters:
    ///   - displayText: display text for the pill
    ///   - font: the text font
    /// - Returns: required size for pill
    static func size(forDisplayText displayText: String, andFont font: UIFont) -> CGSize {
        let label = UILabel(frame: .zero)
        label.text = displayText
        label.font = font
        let labelSize = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                                                  height: pillAttachmentViewSizes.pillBackgroundHeight))

        return CGSize(width: labelSize.width + pillAttachmentViewSizes.totalWidthWithoutLabel,
                      height: pillAttachmentViewSizes.pillHeight)
    }
}
