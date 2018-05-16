//
//  FriendCellTableViewCell.swift
//  Awaaz
//
//  Created by Maihan Nijat on 2018-05-15.
//  Copyright © 2018 Sunzala Technology. All rights reserved.
//

import UIKit

class FriendCell: UITableViewCell {
    
    // IBOutlets
    @IBOutlet weak var fullName: UILabel!
    @IBOutlet weak var action: UIButton!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
