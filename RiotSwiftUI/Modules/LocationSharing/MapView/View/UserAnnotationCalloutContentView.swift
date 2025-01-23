// 
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Reusable

class UserAnnotationCalloutContentView: UIView, Themable, NibLoadable {
    
    // MARK: - Constants
    
    private static let sizingView = UserAnnotationCalloutContentView.instantiate()
    
    private enum Constants {
        static let height: CGFloat = 44.0
        static let cornerRadius: CGFloat = 8.0
    }
    
    // MARK: - Properties
    
    // MARK: Outlets
    
    @IBOutlet var backgroundView: UIView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var shareButton: UIButton!
    
    // MARK: - Setup
    
    static func instantiate() -> UserAnnotationCalloutContentView {
        return UserAnnotationCalloutContentView.loadFromNib()
    }
    
    // MARK: - Public
    
    func update(theme: Theme) {
        self.backgroundView.backgroundColor = theme.colors.background
        self.titleLabel.textColor = theme.colors.secondaryContent
        self.titleLabel.font = theme.fonts.callout
        self.shareButton.tintColor = theme.colors.secondaryContent
    }

    // MARK: - Life cycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        self.titleLabel.text = VectorL10n.locationSharingLiveMapCalloutTitle
        self.backgroundView.layer.masksToBounds = true
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.backgroundView.layer.cornerRadius = Constants.cornerRadius
    }
    
    static func contentViewSize() -> CGSize {
        let sizingView = self.sizingView

        sizingView.frame = CGRect(x: 0, y: 0, width: 1, height: Constants.height)

        sizingView.setNeedsLayout()
        sizingView.layoutIfNeeded()

        let fittingSize = CGSize(width: UIView.layoutFittingCompressedSize.width, height: Constants.height)

        let size = sizingView.systemLayoutSizeFitting(fittingSize,
                                                             withHorizontalFittingPriority: .fittingSizeLevel,
                                                             verticalFittingPriority: .required)

        return size
    }
}
