// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

extension DeviceType {
    
    var image: Image {
        
        let image: Image
        
        switch self {
        case .desktop:
            image = Image(Asset.Images.deviceTypeDesktop.name)
        case .web:
            image = Image(Asset.Images.deviceTypeWeb.name)
        case .mobile:
            image = Image(Asset.Images.deviceTypeMobile.name)
        case .unknown:
            image = Image(Asset.Images.deviceTypeUnknown.name)
        }
        
        return image
    }
    
    var name: String {
        let name: String
        
        let appName = AppInfo.current.displayName
        
        switch self {
        case .desktop:
            name = VectorL10n.deviceNameDesktop(appName)
        case .web:
            name = VectorL10n.deviceNameWeb(appName)
        case .mobile:
            name = VectorL10n.deviceNameMobile(appName)
        case .unknown:
            name = VectorL10n.deviceNameUnknown
        }
        
        return name
    }
}
