// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import DesignKit

struct DarkThemeSwiftUI: ThemeSwiftUI {
    var identifier: ThemeIdentifier = .dark
    let isDark: Bool = true
    var colors: ColorSwiftUI = DarkColors.swiftUI
    var fonts: FontSwiftUI = FontSwiftUI(values: ElementFonts())
}
