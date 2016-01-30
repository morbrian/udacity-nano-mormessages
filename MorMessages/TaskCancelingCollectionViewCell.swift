//
//  TaskCancelingCollectionViewCell.swift
//  MorMessages
//
//  Created by Brian Moriarty on 1/23/16.
//  Copyright © 2016 Brian Moriarty. All rights reserved.
//

import UIKit

class TaskCancelingCollectionViewCell : UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView?
    
    var imageName: String = ""
   
    var taskToCancelifCellIsReused: NSURLSessionTask? {
        
        didSet {
            if let taskToCancel = oldValue {
                taskToCancel.cancel()
            }
        }
    }
}
