//
//  ControlViewModel.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/14/21.
//

import Foundation
import IGListKit

class ControlViewModel: ListDiffable {

    let likeCount: String
    let commentCount: String
    let authenticated: Bool
    let liked: Bool?
    let archived: Bool
    var fromPostControlView: Bool = false
    
    init(likeCount: Int, commentCount: Int, liked: Bool?, authenticated: Bool, archived: Bool) {
        self.likeCount = String(likeCount)
        self.commentCount = String(commentCount)
        self.liked = liked
        self.authenticated = authenticated
        self.archived = archived
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return "control" as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard let object = object as? ControlViewModel else { return false }
        return likeCount == object.likeCount && commentCount == object.commentCount
            && authenticated == object.authenticated && liked == object.liked
    }
}
