//
//  Users.swift
//  ChatChat
//
//  Created by Patrick James White on 6/6/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import Foundation
internal class FBUser : NSObject, NSCoding  {
    internal let uid: String
    internal let name: String
    internal let meuid: String
    
    init(uid: String, name: String,meuid:String) {
        self.uid = uid
        self.name = name
        self.meuid = meuid
    }
    

    
    // MARK: NSCoding
    
    required init(coder decoder: NSCoder) {
        //Error here "missing argument for parameter name in call
        self.uid = decoder.decodeObject(forKey: "uid") as! String
        self.name = decoder.decodeObject(forKey: "name") as! String
        self.meuid = decoder.decodeObject(forKey: "meuid") as! String
        super.init()
    }
    
    
    func encode(with coder: NSCoder) {
        coder.encode(self.uid, forKey: "uid")
        coder.encode(self.name, forKey: "name")
        coder.encode(self.meuid, forKey: "meuid")
        
    }
}
