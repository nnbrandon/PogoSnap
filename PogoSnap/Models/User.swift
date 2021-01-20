//
//  User.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import Foundation
import IGListKit

class User: ListDiffable {
    let username: String
    let user_icon: String?
    
    init(username: String, user_icon: String?) {
        self.username = username
        self.user_icon = user_icon
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return username as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else {return true}
        guard let object = object as? User else {return false}
        return username == object.username && user_icon == object.user_icon
    }
}
