// 
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import AnalyticsEvents

extension AnalyticsEvent.UserProperties {

    //  Initializer for Element. Strips all Web properties.
    public init(ftueUseCaseSelection: FtueUseCaseSelection?, numFavouriteRooms: Int?, numSpaces: Int?, allChatsActiveFilter: Int?) {
        self.init(WebMetaSpaceFavouritesEnabled: nil,
                  WebMetaSpaceHomeAllRooms: nil,
                  WebMetaSpaceHomeEnabled: nil,
                  WebMetaSpaceOrphansEnabled: nil,
                  WebMetaSpacePeopleEnabled: nil,
                  ftueUseCaseSelection: ftueUseCaseSelection,
                  numFavouriteRooms: numFavouriteRooms,
                  numSpaces: numSpaces)
    }

}
