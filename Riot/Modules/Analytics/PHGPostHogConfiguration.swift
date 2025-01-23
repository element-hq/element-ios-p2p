// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import PostHog

extension PHGPostHogConfiguration {
    static var standard: PHGPostHogConfiguration? {
        let analyticsConfiguration = BuildSettings.analyticsConfiguration
        guard analyticsConfiguration.isEnabled else { return nil }
        
        let postHogConfiguration = PHGPostHogConfiguration(apiKey: analyticsConfiguration.apiKey, host: analyticsConfiguration.host)
        postHogConfiguration.shouldSendDeviceID = false
        
        return postHogConfiguration
    }
}
