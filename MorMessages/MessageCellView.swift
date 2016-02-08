//
//  MessageCellView.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/29/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class MessageCellView: TaskCancelingTableViewCell {

    
    @IBOutlet weak var contentLabel: UIBorderLabel!
    
    var message: Message? {
        didSet {
            if let message = message {
                configureCellWithMessage(message)
            } else {
                contentLabel.text = nil
            }
        }
    }
    
    // MARK: - Configure Cell
    
    func configureCellWithMessage(message: Message) {
        contentLabel.text = message.text
        contentLabel.layer.masksToBounds = true
        contentLabel.layer.cornerRadius = 8.0
        contentLabel.topInset = 6
        contentLabel.bottomInset = 6
        contentLabel.leftInset = 10
        contentLabel.rightInset = 10
        
//        contentLabel.sizeToFit()
//        let size = contentLabel.frame.size
//        contentLabel.sizeThatFits(CGSize(width: size.width + 20, height: size.height + 12))
    }
    
    
    
}