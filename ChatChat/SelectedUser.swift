//
//  SelectedUser.swift
//  ChatChat
//
//  Created by Patrick James White on 6/8/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import Foundation

internal class SelectedUser {
    internal let uid: String
    internal let row: Int
    
    init(uid: String, row: Int) {
        self.uid = uid
        self.row = row
    }
}
