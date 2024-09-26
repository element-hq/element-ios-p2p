// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest
import MatrixSDK

private enum Constants {
    static let roomId = "someRoomId"
    static let repliedEventId = "repliedEventId"
    static let repliedEventBody = "Test message"
    static let repliedEventEditedBody = "Edited message"
    static let repliedEventNewContentBody = "New content"
    static let replyBody = "> <@alice:matrix.org> Test message\n\nReply"
    static let replyFormattedBodyWithItalic = "<mx-reply><blockquote><a href=\"https://matrix.to/#/someRoomId/repliedEventId\">In reply to</a> <a href=\"https://matrix.to/#/alice\">alice</a><br>Test message</blockquote></mx-reply><em>Reply</em>"
    static let expectedHTML = "<mx-reply><blockquote><a href=\"https://matrix.to/#/someRoomId/repliedEventId\">In reply to</a> <a href=\"https://matrix.to/#/alice\">alice</a><br>Test message</blockquote></mx-reply>Reply"
    static let expectedEditedHTML = "<mx-reply><blockquote><a href=\"https://matrix.to/#/someRoomId/repliedEventId\">In reply to</a> <a href=\"https://matrix.to/#/alice\">alice</a><br>Edited message</blockquote></mx-reply>Reply"
    static let expectedEditedHTMLWithNewContent = "<mx-reply><blockquote><a href=\"https://matrix.to/#/someRoomId/repliedEventId\">In reply to</a> <a href=\"https://matrix.to/#/alice\">alice</a><br>New content</blockquote></mx-reply>Reply"
    static let expectedEditedHTMLWithParsedItalic = "<mx-reply><blockquote><a href=\"https://matrix.to/#/someRoomId/repliedEventId\">In reply to</a> <a href=\"https://matrix.to/#/alice\">alice</a><br>New content</blockquote></mx-reply><em>Reply</em>"
}

class MXKEventFormatterTests: XCTestCase {
    func testBuildHTMLString() {
        let formatter = MXKEventFormatter()
        let repliedEvent = MXEvent()
        let event = MXEvent()
        func buildHTML() -> String? { return formatter.buildHTMLString(for: event, inReplyTo: repliedEvent) }

        // Initial setup.
        repliedEvent.sender = "alice"
        repliedEvent.roomId = Constants.roomId
        repliedEvent.eventId = Constants.repliedEventId
        repliedEvent.wireType = kMXEventTypeStringRoomMessage
        repliedEvent.wireContent = [kMXMessageTypeKey: kMXMessageTypeText,
                                    kMXMessageBodyKey: Constants.repliedEventBody]
        event.sender = "bob"
        event.wireType = kMXEventTypeStringRoomMessage
        event.wireContent = [
            kMXMessageTypeKey: kMXMessageTypeText,
            kMXMessageBodyKey: Constants.replyBody,
            kMXEventRelationRelatesToKey: [kMXEventContentRelatesToKeyInReplyTo: ["event_id": Constants.repliedEventId]]
        ]

        // Default render.
        XCTAssertEqual(buildHTML(), Constants.expectedHTML)

        // Render after edition.
        repliedEvent.wireContent[kMXMessageBodyKey] = Constants.repliedEventEditedBody
        XCTAssertEqual(buildHTML(), Constants.expectedEditedHTML)

        // m.new_content has prioritiy over base content.
        repliedEvent.wireContent[kMXMessageContentKeyNewContent] = [kMXMessageBodyKey: Constants.repliedEventNewContentBody]
        XCTAssertEqual(buildHTML(), Constants.expectedEditedHTMLWithNewContent)

        // If reply's formatted_body is available it's used to construct a brand new HTML.
        event.wireContent["formatted_body"] = Constants.replyFormattedBodyWithItalic
        XCTAssertEqual(buildHTML(), Constants.expectedEditedHTMLWithParsedItalic)

        // If content from replied event is missing. Reply can't be constructed (client will use fallback).
        repliedEvent.wireContent[kMXMessageBodyKey] = nil
        repliedEvent.wireContent[kMXMessageContentKeyNewContent] = nil
        XCTAssertNil(buildHTML())
    }
}
