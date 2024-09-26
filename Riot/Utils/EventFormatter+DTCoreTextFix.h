/*
Copyright 2020-2024 New Vector Ltd.

SPDX-License-Identifier: AGPL-3.0-only
Please see LICENSE in the repository root for full details.
*/

@import Foundation;

#import "EventFormatter.h"

NS_ASSUME_NONNULL_BEGIN

@interface EventFormatter(DTCoreTextFix)

// Fix DTCoreText iOS 13 issue (https://github.com/Cocoanetics/DTCoreText/issues/1168)
+ (void)fixDTCoreTextFont;

@end

NS_ASSUME_NONNULL_END
