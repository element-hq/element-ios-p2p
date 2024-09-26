/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import <UIKit/UIKit.h>

#import <MatrixSDK/MatrixSDK.h>

/**
 The `RoomKeyRequestViewController` display a modal dialog at the top of the
 application asking the user if he wants to share room keys with a user's device.
 For the moment, the user is himself.
 */
@interface RoomKeyRequestViewController : NSObject

/**
 The UIAlertController instance which handles the dialog.
 */
@property (nonatomic, readonly) UIAlertController *alertController;

@property (nonatomic, readonly) MXSession *mxSession;
@property (nonatomic, readonly) MXDeviceInfo *device;

/**
 Initialise an `RoomKeyRequestViewController` instance.

 @param deviceInfo the device to share keys to.
 @param wasNewDevice flag indicating whether this is the first time we meet the device.
 @param session the related matrix session.
 @param onComplete a block called when the the dialog is closed.
 @return the newly created instance.
 */
- (instancetype)initWithDeviceInfo:(MXDeviceInfo*)deviceInfo wasNewDevice:(BOOL)wasNewDevice andMatrixSession:(MXSession*)session onComplete:(void (^)(void))onComplete;

/**
 Show the dialog in a modal way.
 */
- (void)show;

/**
 Hide the dialog.
 */
- (void)hide;

@end
