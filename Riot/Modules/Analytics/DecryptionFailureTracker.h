/*
Copyright 2018-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <Foundation/Foundation.h>

@class DecryptionFailureTracker;

@class Analytics;
@import MatrixSDK;

@interface DecryptionFailureTracker : NSObject

/**
 Returns the shared tracker.

 @return the shared tracker.
 */
+ (instancetype)sharedInstance;

/**
 The delegate object to receive analytics events.
 */
@property (nonatomic, weak) Analytics *delegate;

/**
 Report an event unable to decrypt.

 This error can be momentary. The DecryptionFailureTracker will check if it gets
 fixed. Else, it will generate a failure (@see `trackFailures`).

 @param event the event.
 @param roomState the room state when the event was received.
 @param userId my user id.
 */
- (void)reportUnableToDecryptErrorForEvent:(MXEvent*)event withRoomState:(MXRoomState*)roomState myUser:(NSString*)userId;

/**
 Flush current data.
 */
- (void)dispatch;

@end
