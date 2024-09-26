/*
Copyright 2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "RoomKeyRequestViewController.h"

#import "GeneratedInterface-Swift.h"

@interface RoomKeyRequestViewController () <KeyVerificationCoordinatorBridgePresenterDelegate>
{
    void (^onComplete)(void);

    KeyVerificationCoordinatorBridgePresenter *keyVerificationCoordinatorBridgePresenter;

    BOOL wasNewDevice;
}
@end

@implementation RoomKeyRequestViewController

- (instancetype)initWithDeviceInfo:(MXDeviceInfo *)deviceInfo wasNewDevice:(BOOL)theWasNewDevice andMatrixSession:(MXSession *)session onComplete:(void (^)(void))onCompleteBlock
{
    self = [super init];
    if (self)
    {
        _mxSession = session;
        _device = deviceInfo;
        wasNewDevice = theWasNewDevice;
        onComplete = onCompleteBlock;
    }
    return self;
}

- (void)show
{
    // Show it modally on the root view controller
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (rootViewController)
    {
        NSString *title = [VectorL10n e2eRoomKeyRequestTitle];
        NSString *message;
        if (wasNewDevice)
        {
            message = [VectorL10n e2eRoomKeyRequestMessageNewDevice:_device.displayName];
        }
        else
        {
            message = [VectorL10n e2eRoomKeyRequestMessage:_device.displayName];
        }

        _alertController = [UIAlertController alertControllerWithTitle:title
                                                               message:message
                                                        preferredStyle:UIAlertControllerStyleAlert];

        __weak typeof(self) weakSelf = self;

        [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eRoomKeyRequestStartVerification]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   self->_alertController = nil;
                                                                   [self showVerificationView];
                                                               }
                                                           }]];

        [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eRoomKeyRequestShareWithoutVerifying]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   self->_alertController = nil;

                                                                   // Accept the received requests from this device
                                                                   [self.mxSession.crypto acceptAllPendingKeyRequestsFromUser:self.device.userId andDevice:self.device.deviceId onComplete:^{

                                                                       self->onComplete();
                                                                   }];
                                                               }
                                                           }]];

        [_alertController addAction:[UIAlertAction actionWithTitle:[VectorL10n e2eRoomKeyRequestIgnoreRequest]
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * action) {

                                                               if (weakSelf)
                                                               {
                                                                   typeof(self) self = weakSelf;

                                                                   self->_alertController = nil;

                                                                   // Ignore all pending requests from this device
                                                                   [self.mxSession.crypto ignoreAllPendingKeyRequestsFromUser:self.device.userId andDevice:self.device.deviceId onComplete:^{

                                                                       self->onComplete();
                                                                   }];
                                                               }
                                                           }]];

        [rootViewController presentViewController:_alertController animated:YES completion:nil];
    }
}

- (void)hide
{
    if (_alertController)
    {
        [_alertController dismissViewControllerAnimated:YES completion:nil];
        _alertController = nil;
    }
}


- (void)showVerificationView
{
    // Show it modally on the root view controller
    UIViewController *rootViewController = [AppDelegate theDelegate].window.rootViewController;
    if (rootViewController)
    {
        keyVerificationCoordinatorBridgePresenter = [[KeyVerificationCoordinatorBridgePresenter alloc] initWithSession:_mxSession];
        keyVerificationCoordinatorBridgePresenter.delegate = self;

        [keyVerificationCoordinatorBridgePresenter presentFrom:rootViewController otherUserId:_device.userId otherDeviceId:_device.deviceId animated:YES];
    }
}

#pragma mark - DeviceVerificationCoordinatorBridgePresenterDelegate

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidComplete:(KeyVerificationCoordinatorBridgePresenter *)coordinatorBridgePresenter otherUserId:(NSString * _Nonnull)otherUserId otherDeviceId:(NSString * _Nonnull)otherDeviceId
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)keyVerificationCoordinatorBridgePresenterDelegateDidCancel:(KeyVerificationCoordinatorBridgePresenter * _Nonnull)coordinatorBridgePresenter
{
    [self dismissKeyVerificationCoordinatorBridgePresenter];
}

- (void)dismissKeyVerificationCoordinatorBridgePresenter
{
    [keyVerificationCoordinatorBridgePresenter dismissWithAnimated:YES completion:nil];
    keyVerificationCoordinatorBridgePresenter = nil;
    
    // Check device new status
    [self.mxSession.crypto downloadKeys:@[self.device.userId] forceDownload:NO success:^(MXUsersDevicesMap<MXDeviceInfo *> *usersDevicesInfoMap, NSDictionary<NSString *,MXCrossSigningInfo *> *crossSigningKeysMap) {
        
        MXDeviceInfo *deviceInfo = [usersDevicesInfoMap objectForDevice:self.device.deviceId forUser:self.device.userId];
        if (deviceInfo && deviceInfo.trustLevel.localVerificationStatus == MXDeviceVerified)
        {
            // Accept the received requests from this device
            // As the device is now verified, all other key requests will be automatically accepted.
            [self.mxSession.crypto acceptAllPendingKeyRequestsFromUser:self.device.userId andDevice:self.device.deviceId onComplete:^{
                
                self->onComplete();
            }];
        }
        else
        {
            // Come back to self.alertController - ie, reopen it
            [self show];
        }
    } failure:^(NSError *error) {
        
        // Should not happen (the device is in the crypto db)
        [self show];
    }];
}

@end
