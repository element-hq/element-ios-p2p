// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

class MXNotificationSettingsService: NotificationSettingsServiceType {
    
    private let session: MXSession
    private var cancellables = Set<AnyCancellable>()
    
    @Published private var contentRules = [MXPushRule]()
    @Published private var rules = [MXPushRule]()
    
    var rulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $rules.map({ $0.map({ $0 as NotificationPushRuleType }) }).eraseToAnyPublisher()
    }
    
    var contentRulesPublisher: AnyPublisher<[NotificationPushRuleType], Never> {
        $contentRules.map({ $0.map({ $0 as NotificationPushRuleType }) }).eraseToAnyPublisher()
    }
    
    init(session: MXSession) {
        self.session = session
        // Publisher of all rule updates
        let rulesUpdated = NotificationCenter.default.publisher(for: NSNotification.Name(rawValue: kMXNotificationCenterDidUpdateRules))
        
        // Set initial value of the content rules
        if let contentRules = session.notificationCenter.rules.global.content as? [MXPushRule] {
            self.contentRules = contentRules
        }
        
        // Observe future updates to content rules
        rulesUpdated
            .compactMap({ _ in self.session.notificationCenter.rules.global.content as? [MXPushRule] })
            .assign(to: &$contentRules)
        
        // Set initial value of rules
        if let flatRules = session.notificationCenter.flatRules as? [MXPushRule] {
            rules = flatRules
        }
        // Observe future updates to rules
        rulesUpdated
            .compactMap({ _ in self.session.notificationCenter.flatRules as? [MXPushRule] })
            .assign(to: &$rules)
    }
    
    func add(keyword: String, enabled: Bool) {
        let index = NotificationIndex.index(when: enabled)
        guard let actions = NotificationPushRuleId.keywords.standardActions(for: index)?.actions
        else {
            return
        }
        session.notificationCenter.addContentRuleWithRuleId(matchingPattern: keyword, notify: actions.notify, sound: actions.sound, highlight: actions.highlight)
    }
    
    func remove(keyword: String) {
        guard let rule = session.notificationCenter.rule(byId: keyword) else { return }
        session.notificationCenter.removeRule(rule)
    }
    
    func updatePushRuleActions(for ruleId: String, enabled: Bool, actions: NotificationActions?) {
        guard let rule = session.notificationCenter.rule(byId: ruleId) else { return }
        session.notificationCenter.enableRule(rule, isEnabled: enabled)
        
        if let actions = actions {
            session.notificationCenter.updatePushRuleActions(ruleId,
                                                             kind: rule.kind,
                                                             notify: actions.notify,
                                                             soundName: actions.sound,
                                                             highlight: actions.highlight)
        }
    }
}
