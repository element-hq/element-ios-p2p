// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

#import <Foundation/Foundation.h>
@import Intents;
@protocol ContactResolving;

NS_ASSUME_NONNULL_BEGIN

@interface StartVideoCallIntentHandler : NSObject <INStartVideoCallIntentHandling>

- (instancetype)initWithContactResolver:(id<ContactResolving>)contactResolver;

@end

NS_ASSUME_NONNULL_END
