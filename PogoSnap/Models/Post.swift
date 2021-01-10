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
    let imageSources: [ImageSource]
    var score: Int
    let numComments: Int
    let commentsLink: String
    let archived: Bool
    let id: String
    let created_utc: TimeInterval
    var liked: Bool?
    let aspectFit: Bool
    var user_icon: String?
    let subReddit: String
    
    static func == (lhs: Post, rhs: Post) -> Bool {
        return lhs.author == rhs.author && lhs.title == rhs.title && lhs.score != rhs.score && lhs.numComments != rhs.numComments
    }
}
