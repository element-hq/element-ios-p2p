// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import PostHog
import AnalyticsEvents

/// An analytics client that reports events to a PostHog server.
class PostHogAnalyticsClient: AnalyticsClientProtocol {
    /// The PHGPostHog object used to report events.
    private var postHog: PHGPostHog?
    
    /// Any user properties to be included with the next captured event.
    private(set) var pendingUserProperties: AnalyticsEvent.UserProperties?
    
    var isRunning: Bool { postHog?.enabled ?? false }
    
    func start() {
        // Only start if analytics have been configured in BuildSettings
        guard let configuration = PHGPostHogConfiguration.standard else { return }
        
        if postHog == nil {
            postHog = PHGPostHog(configuration: configuration)
        }
        
        postHog?.enable()
    }
    
    func identify(id: String) {
        if let userProperties = pendingUserProperties {
            // As user properties overwrite old ones, compactMap the dictionary to avoid resetting any missing properties
            postHog?.identify(id, properties: userProperties.properties.compactMapValues { $0 })
            pendingUserProperties = nil
        } else {
            postHog?.identify(id)
        }
    }
    
    func reset() {
        postHog?.reset()
        pendingUserProperties = nil
    }
    
    func stop() {
        postHog?.disable()
        
        // As of PostHog 1.4.4, setting the client to nil here doesn't release
        // it. Keep it around to avoid having multiple instances if the user re-enables
    }
    
    func flush() {
        postHog?.flush()
    }
    
    func capture(_ event: AnalyticsEventProtocol) {
        postHog?.capture(event.eventName, properties: attachUserProperties(to: event.properties))
    }
    
    func screen(_ event: AnalyticsScreenProtocol) {
        postHog?.screen(event.screenName.rawValue, properties: attachUserProperties(to: event.properties))
    }
    
    func updateUserProperties(_ userProperties: AnalyticsEvent.UserProperties) {
        guard let pendingUserProperties = pendingUserProperties else {
            pendingUserProperties = userProperties
            return
        }
        
        // Merge the updated user properties with the existing ones
        self.pendingUserProperties = AnalyticsEvent.UserProperties(ftueUseCaseSelection: userProperties.ftueUseCaseSelection ?? pendingUserProperties.ftueUseCaseSelection,
                                                                   numFavouriteRooms: userProperties.numFavouriteRooms ?? pendingUserProperties.numFavouriteRooms,
                                                                   numSpaces: userProperties.numSpaces ?? pendingUserProperties.numSpaces,
                                                                   allChatsActiveFilter: nil)
    }
    
    // MARK: - Private
    
    /// Given a dictionary containing properties from an event, this method will return those properties
    /// with any pending user properties included under the `$set` key.
    /// - Parameter properties: A dictionary of properties from an event.
    /// - Returns: The `properties` dictionary with any user properties included.
    private func attachUserProperties(to properties: [String: Any]) -> [String: Any] {
        guard isRunning, let userProperties = pendingUserProperties else { return properties }
        
        var properties = properties
        
        // As user properties overwrite old ones via $set, compactMap the dictionary to avoid resetting any missing properties
        properties["$set"] = userProperties.properties.compactMapValues { $0 }
        pendingUserProperties = nil
        return properties
    }
}
