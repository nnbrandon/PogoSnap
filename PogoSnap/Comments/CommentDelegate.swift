//
//  CommentDelegate.swift
//  PogoSnap
//
//  Created by Brandon Nguyen on 1/16/21.
//

import Foundation

protocol CommentDelegate: class {
    func didTapUsername(username: String)
    func didTapReply(parentCommentId: String, parentCommentContent: String, parentCommentAuthor: String, parentDepth: Int)
    func didTapOptions(commentId: String, author: String)
    func didTapMoreChildren(children: [String])
}
