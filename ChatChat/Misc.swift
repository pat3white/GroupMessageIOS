//
//  Misc.swift
//  ChatChat
//
//  Created by Patrick James White on 6/2/17.
//  Copyright © 2017 Razeware LLC. All rights reserved.
//

import Foundation
import UIKit



extension UIColor {
    
    //237/225/206 light sand/white color
    static func mainColor()->UIColor{
        return UIColor(red:0.161 ,green:0.31, blue:0.427, alpha:1.0)
        //return flatWhiteColor()
    }
    
    static func compColor()->UIColor{
        return UIColor(red:0.667 ,green:0.349, blue:0.224, alpha:1.0)
        //return flatWhiteColor()
    }
    
    func adjust(_ red: CGFloat, green: CGFloat, blue: CGFloat, alpha:CGFloat) -> UIColor{
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        var w: CGFloat = 0
        self.getRed(&r, green: &g, blue: &b, alpha: &a)
        return UIColor(red: r+red, green: g+green, blue: b+blue, alpha: a+alpha)
    }
    convenience init(red: Int, green: Int, blue: Int) {
        assert(red >= 0 && red <= 255, "Invalid red component")
        assert(green >= 0 && green <= 255, "Invalid green component")
        assert(blue >= 0 && blue <= 255, "Invalid blue component")
        
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(netHex:Int) {
        self.init(red:(netHex >> 16) & 0xff, green:(netHex >> 8) & 0xff, blue:netHex & 0xff)
    }
    
    
}
