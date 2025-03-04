// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// `VectorHostingBottomSheetPreferences` defines the bottom sheet behaviour using the `UISheetPresentationController` of the `UIViewController`
class VectorHostingBottomSheetPreferences {
    
    // MARK: - Detent
    
    enum Detent {
        case medium
        case large
        
        @available(iOS 15, *)
        fileprivate func uiSheetDetent() -> UISheetPresentationController.Detent {
            switch self {
            case .medium: return .medium()
            case .large: return .large()
            }
        }
        
        @available(iOS 15, *)
        fileprivate func uiSheetDetentId() -> UISheetPresentationController.Detent.Identifier {
            switch self {
            case .medium: return .medium
            case .large: return .large
            }
        }
    }
    
    // MARK: - Public
    
    // The array of detents that the sheet may rest at.
    // This array must have at least one element.
    // Detents must be specified in order from smallest to largest height.
    // Default: [.medium, .large]
    let detents: [Detent]
    
    // The default detent. When nil or the identifier is not found in detents, the sheet is displayed at the smallest detent.
    // Default: nil
    let defaultDetent: Detent?
    
    // The largest detent that is not dimmed. When nil or the identifier is not found in detents, all detents are dimmed.
    // Default: nil
    let largestUndimmedDetent: Detent?
    let cornerRadius: CGFloat?
    
    // If there is a larger detent to expand to than the selected detent, and a descendent scroll view is scrolled to top, this controls whether scrolling down will expand to a larger detent.
    // Useful to set to NO for non-modal sheets, where scrolling in the sheet should not expand the sheet and obscure the content above.
    // Default: YES
    let prefersScrollingExpandsWhenScrolledToEdge: Bool
    
    // Set to YES to show a grabber at the top of the sheet.
    // Default: `nil` -> the grabber is shown if more than one detent is configured
    let prefersGrabberVisible: Bool?
    
    // MARK: - Setup
    
    init(detents: [Detent] = [.medium, .large],
         defaultDetent: Detent? = nil,
         largestUndimmedDetent: Detent? = nil,
         prefersGrabberVisible: Bool? = nil,
         cornerRadius: CGFloat? = nil,
         prefersScrollingExpandsWhenScrolledToEdge: Bool = true) {
        self.detents = detents
        self.defaultDetent = defaultDetent
        self.largestUndimmedDetent = largestUndimmedDetent
        self.prefersGrabberVisible = prefersGrabberVisible
        self.cornerRadius = cornerRadius
        self.prefersScrollingExpandsWhenScrolledToEdge = prefersScrollingExpandsWhenScrolledToEdge
    }
    
    // MARK: - Public
    
    func setup(viewController: UIViewController) {
        guard #available(iOS 15.0, *) else { return }
        
        guard let sheetController = viewController.sheetPresentationController else {
            MXLog.debug("[VectorHostingBottomSheetPreferences] setup: no sheetPresentationController found")
            return
        }
        
        sheetController.detents = self.uiSheetDetents()
        if let prefersGrabberVisible = self.prefersGrabberVisible {
            sheetController.prefersGrabberVisible = prefersGrabberVisible
        } else {
            sheetController.prefersGrabberVisible = self.detents.count > 1
        }
        sheetController.selectedDetentIdentifier = self.defaultDetent?.uiSheetDetentId()
        sheetController.largestUndimmedDetentIdentifier = self.largestUndimmedDetent?.uiSheetDetentId()
        sheetController.prefersScrollingExpandsWhenScrolledToEdge = self.prefersScrollingExpandsWhenScrolledToEdge
        if let cornerRadius = self.cornerRadius {
            sheetController.preferredCornerRadius = cornerRadius
        }
    }
    
    // MARK: - Private

    @available(iOS 15, *)
    fileprivate func uiSheetDetents() -> [UISheetPresentationController.Detent] {
        var uiSheetDetents: [UISheetPresentationController.Detent] = []
        for detent in detents {
            uiSheetDetents.append(detent.uiSheetDetent())
        }
        return uiSheetDetents
    }
}
