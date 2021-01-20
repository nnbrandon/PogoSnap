//
//  Post.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 11/17/20.
//

import Foundation
import IGListKit

final class Post: ListDiffable {
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
    
    init(author: String, title: String, imageSources: [ImageSource], score: Int, numComments: Int, commentsLink: String, archived: Bool, id: String,
         created_utc: TimeInterval, liked: Bool?, aspectFit: Bool, user_icon: String?, subReddit: String) {
        self.author = author
        self.title = title
        self.imageSources = imageSources
        self.score = score
        self.numComments = numComments
        self.commentsLink = commentsLink
        self.archived = archived
        self.id = id
        self.created_utc = created_utc
        self.liked = liked
        self.aspectFit = aspectFit
        self.user_icon = user_icon
        self.subReddit = subReddit
    }
    
    func diffIdentifier() -> NSObjectProtocol {
        return id as NSObjectProtocol
    }
    
    func isEqual(toDiffableObject object: ListDiffable?) -> Bool {
        guard self !== object else {return true}
        guard let object = object as? Post else {return false}
        return author == object.author && title == object.title && score == object.score && liked == object.liked && id == object.id
    }
    
    static func postFactory(post: Post) -> Post {
        return Post(author: post.author, title: post.title, imageSources: post.imageSources, score: post.score, numComments: post.numComments, commentsLink: post.commentsLink, archived: post.archived, id: post.id, created_utc: post.created_utc, liked: post.liked, aspectFit: post.aspectFit, user_icon: post.user_icon, subReddit: post.subReddit)
    }
}
