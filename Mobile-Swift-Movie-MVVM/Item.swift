//
//  Item.swift
//  Mobile-Swift-Movie-MVVM
//
//  Created by Macbook Cakra M4 on 28/10/26.
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
