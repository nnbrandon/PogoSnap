//
//  Comment.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/21/20.
//

import Foundation

struct Comment {
    let author: String
    let body: String
    let depth: Int
    let replies: [Comment]
    let isAuthorPost: Bool
    var isFolded: Bool = false
}
