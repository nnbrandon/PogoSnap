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
    let imageUrls: [String]
    let score: Int
    let numComments: Int
    let commentsLink: String
    let archived: Bool
    let id: String
    let liked: Bool?
    
    static func ==(lhs: Post, rhs: Post) -> Bool {
        return lhs.author == rhs.author && lhs.imageUrls == rhs.imageUrls && lhs.title == rhs.title
    }
}
