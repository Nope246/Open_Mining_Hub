// Project- Bitaxe Dashboard
//  item.swift
//  bitaxe
//
//  Created by Brent Parks on 5/31/25.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}

//  end of item.swift
