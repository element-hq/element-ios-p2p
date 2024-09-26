/*
Copyright 2018-2024 New Vector Ltd.
Copyright 2017 Vector Creations Ltd

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
 */

#import "MXRoomSummary+Riot.h"

#import "AvatarGenerator.h"

#import "GeneratedInterface-Swift.h"

@implementation MXRoomSummary (Riot)

- (void)setRoomAvatarImageIn:(MXKImageView*)mxkImageView
{
    [mxkImageView vc_setRoomAvatarImageWith:self.avatar
                                     roomId:self.roomId
                                displayName:self.displayname
                               mediaManager:self.mxSession.mediaManager];
}

- (RoomEncryptionTrustLevel)roomEncryptionTrustLevel
{
    RoomEncryptionTrustLevel roomEncryptionTrustLevel = RoomEncryptionTrustLevelUnknown;
    if (self.trust)
    {
        double trustedUsersPercentage = self.trust.trustedUsersProgress.fractionCompleted;
        double trustedDevicesPercentage = self.trust.trustedDevicesProgress.fractionCompleted;

        if (trustedUsersPercentage >= 1.0)
        {
            if (trustedDevicesPercentage >= 1.0)
            {
                roomEncryptionTrustLevel = RoomEncryptionTrustLevelTrusted;
            }
            else
            {
                roomEncryptionTrustLevel = RoomEncryptionTrustLevelWarning;
            }
        }
        else
        {
            roomEncryptionTrustLevel = RoomEncryptionTrustLevelNormal;
        }
            
        roomEncryptionTrustLevel = roomEncryptionTrustLevel;
    }
    
    return roomEncryptionTrustLevel;
}

- (BOOL)isJoined
{
    return self.membership == MXMembershipJoin || self.membershipTransitionState == MXMembershipTransitionStateJoined;
}

@end
