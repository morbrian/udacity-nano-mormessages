//
//  Constants.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/22/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import Foundation
import UIKit

// Constants used Application wide
struct Constants {
    
    // MARK: Application Info
    
    static let GravatarImageSize = 80.0
    static let ForumNoImage = "ForumNoImage"
    static let ForumFetchingImage = "ForumFetchingImage"
    static let MorMessagesInverseImage = "MorMessagesInverseImage"
    
    // MARK: StoryBoard Identifiers
    
    static let SuccessfulLoginSegue = "SuccessfulLoginSegue"
    static let ReturnToLoginScreenSegue = "ReturnToLoginScreenSegue"
    static let ShowMessageListSegue = "ShowMessageListSegue"
    static let AddForumSegue = "AddForumSegue"
    static let AddMessageSegue = "AddMessageSegue"
    static let ForumCellViewIdentifier = "ForumCellViewIdentifier"
    static let DetailsCellViewIdentifier = "DetailsCellViewIdentifier"
    static let MessageCellViewRightIdentifier = "MessageCellViewRightIdentifier"
    static let MessageCellViewLeftIdentifier = "MessageCellViewLeftIdentifier"
    static let ShowDetailsSegue = "ShowDetailsSegue"
    
    // MARK: Physical Device Info
    
    static let DeviceiPhone5Height = 568.0
    static let DeviceiPhone5Width = 320.0
    
    // MARK: Theme Look and Feel
    static let ThemeStrongColor = UIColor.purpleColor()
    static let ThemeButtonTintColor = ThemeStrongColor
    static let DefaultForumDescriptionText = "Forum Description"
    static let DefaultMessageText = "Message"
    static let DefaultMessageTextPlaceHolderColor = UIColor.lightGrayColor()
    
}
