//
//  ImageUrlDelete.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 12/5/20.
//

import Foundation

@objc(ImageUrlDelete)
class ImageUrlDelete: NSObject, NSCoding {
    let url: String
    let deleteHash: String
    
    init(url: String, deleteHash: String) {
        self.url = url
        self.deleteHash = deleteHash
    }

    required convenience init(coder aDecoder: NSCoder) {
        let url = aDecoder.decodeObject(forKey: "url") as! String
        let deleteHash = aDecoder.decodeObject(forKey: "deleteHash") as! String
        self.init(url: url, deleteHash: deleteHash)
    }

    func encode(with aCoder: NSCoder) {
        aCoder.encode(url, forKey: "url")
        aCoder.encode(deleteHash, forKey: "deleteHash")
    }
    
    static func ==(lhs: ImageUrlDelete, rhs: ImageUrlDelete) -> Bool {
        return lhs.url == rhs.url && lhs.deleteHash == rhs.deleteHash
    }
}
