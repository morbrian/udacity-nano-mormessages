//
//  UIBorderLabel.swift
//  MorMessages
//
//  Created by Brian Moriarty on 2/7/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//
// got the basic idea for this from obj-c code at:
// https://userflex.wordpress.com/2012/04/05/uilabel-custom-insets/

import Foundation
import UIKit

class UIBorderLabel: UILabel {
    
    var topInset: CGFloat = 0.0
    var leftInset: CGFloat = 0.0
    var bottomInset: CGFloat = 0.0
    var rightInset: CGFloat = 0.0
    
    
    override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: topInset, left: leftInset, bottom: bottomInset, right: rightInset)
        return super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}