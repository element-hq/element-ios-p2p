// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// The static list of mocked screens in RiotSwiftUI
enum MockAppScreens {
    static let appScreens: [MockScreenState.Type] = [
        MockUserSessionsOverviewScreenState.self,
        MockLiveLocationLabPromotionScreenState.self,
        MockLiveLocationSharingViewerScreenState.self,
        MockAuthenticationLoginScreenState.self,
        MockAuthenticationReCaptchaScreenState.self,
        MockAuthenticationTermsScreenState.self,
        MockAuthenticationVerifyEmailScreenState.self,
        MockAuthenticationVerifyMsisdnScreenState.self,
        MockAuthenticationRegistrationScreenState.self,
        MockAuthenticationServerSelectionScreenState.self,
        MockAuthenticationForgotPasswordScreenState.self,
        MockAuthenticationChoosePasswordScreenState.self,
        MockAuthenticationSoftLogoutScreenState.self,
        MockOnboardingCelebrationScreenState.self,
        MockOnboardingAvatarScreenState.self,
        MockOnboardingDisplayNameScreenState.self,
        MockOnboardingCongratulationsScreenState.self,
        MockOnboardingUseCaseSelectionScreenState.self,
        MockOnboardingSplashScreenScreenState.self,
        MockStaticLocationViewingScreenState.self,
        MockLocationSharingScreenState.self,
        MockAnalyticsPromptScreenState.self,
        MockUserSuggestionScreenState.self,
        MockPollEditFormScreenState.self,
        MockSpaceCreationEmailInvitesScreenState.self,
        MockSpaceSettingsScreenState.self,
        MockRoomAccessTypeChooserScreenState.self,
        MockRoomUpgradeScreenState.self,
        MockMatrixItemChooserScreenState.self,
        MockSpaceCreationMenuScreenState.self,
        MockSpaceCreationRoomsScreenState.self,
        MockSpaceCreationSettingsScreenState.self,
        MockSpaceCreationPostProcessScreenState.self,
        MockTimelinePollScreenState.self,
        MockChangePasswordScreenState.self,
        MockTemplateSimpleScreenScreenState.self,
        MockTemplateUserProfileScreenState.self,
        MockTemplateRoomListScreenState.self,
        MockTemplateRoomChatScreenState.self,
        MockSpaceSelectorScreenState.self
    ]
}

