//
//  Resturant.swift
//  edotfood
//
//  Created by Eric Mills on 10/30/18.
//  Copyright © 2018 edotmills llc. All rights reserved.
//

import Foundation

struct Resturant {
    var name:String?
    var image_url:String?
    var categories:[Category]?
    var distance:Double?
}

struct Category {
    var alias:String?
    var title:String?
}

