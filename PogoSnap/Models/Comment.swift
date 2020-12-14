//
//  Comment.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/21/20.
//

import Foundation

struct Comment: Equatable {
    var author: String
    var body: String
    let depth: Int
    var replies: [Comment]
    let id: String
    let isAuthorPost: Bool
    var isFolded: Bool = false
    let created_utc: TimeInterval
    
    static func == (lhs: Comment, rhs: Comment) -> Bool {
        return lhs.author == rhs.author && lhs.body == rhs.body && lhs.id == rhs.id
    }
    
}
