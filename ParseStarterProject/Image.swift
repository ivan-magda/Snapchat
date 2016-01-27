//
//  Image.swift
//  ParseStarterProject-Swift
//
//  Created by Иван Магда on 27.01.16.
//  Copyright © 2016 Parse. All rights reserved.
//

import Foundation
import Parse

class Image: PFObject, PFSubclassing {
    //--------------------------------------
    // MARK: - Types
    //--------------------------------------
    
    enum FieldKey: String {
        case recipientUsername
        case senderUsername
        case photo
    }
    
    //--------------------------------------
    // MARK: - Properties
    //--------------------------------------
    
    @NSManaged var recipientUsername: String
    
    @NSManaged var senderUsername: String
    
    @NSManaged var photo: PFFile
    
    //--------------------------------------
    // MARK: - PFSubclassing
    //--------------------------------------
    
    override class func initialize() {
        struct Static {
            static var onceToken : dispatch_once_t = 0;
        }
        dispatch_once(&Static.onceToken) {
            self.registerSubclass()
        }
    }
    
    /// Class name of the Category object.
    class func parseClassName() -> String {
        return "Image"
    }
}

