//
//  ResturantCell.swift
//  edotfood
//
//  Created by Eric Mills on 10/31/18.
//  Copyright © 2018 edotmills llc. All rights reserved.
//

import UIKit

class ResturantCell: UITableViewCell {
    
    @IBOutlet var rest_name:UILabel!
    @IBOutlet var rest_type:UILabel!
    @IBOutlet var rest_distance:UILabel!
    @IBOutlet var rest_imageeview:UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
