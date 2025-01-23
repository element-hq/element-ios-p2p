// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

class MockNotificationSettingsService: NotificationSettingsServiceType, ObservableObject {
    static let example = MockNotificationSettingsService()
    
    @Published var keywords = Set<String>()
    @Published var rules = [NotificationPushRuleType]()
    @Published var contentRules = [NotificationPushRuleType]()
    
    var contentRulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $contentRules.eraseToAnyPublisher()
    }
    
    var keywordsPublisher: AnyPublisher<Set<String>, Never> {
        $keywords.eraseToAnyPublisher()
    }
    
    var rulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $rules.eraseToAnyPublisher()
    }
    
    func add(keyword: String, enabled: Bool) {
        keywords.insert(keyword)
    }
    
    func remove(keyword: String) {
        keywords.remove(keyword)
    }
    
    func updatePushRuleActions(for ruleId: String, enabled: Bool, actions: NotificationActions?) {
        
    }
}
