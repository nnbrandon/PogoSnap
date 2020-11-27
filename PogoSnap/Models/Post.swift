//
//  Post.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import Foundation

struct Post: Equatable {
    let author: String
    let title: String
    let imageUrl: String
    let score: Int
    let numComments: Int
    let commentsLink: String
    
    static func ==(lhs: Post, rhs: Post) -> Bool {
        return lhs.author == rhs.author && lhs.imageUrl == rhs.imageUrl && lhs.title == rhs.title
    }
}
